require "rubygems"
require "activesupport"
require "cgi"
require "hpricot"

module Tangram
  module ContactGetter
    FORMATS = {
      :yml => 'text/yml',
      :xml => 'application/xml',
      :csv => 'text/csv'
    }
    
    def self.new_app(options)
      const_get(options[:app].classify).new(options)
    end
    def self.app_exists?(app)
      const_defined?(app.classify)
    end
    
    class ContactApp
      def initialize(options)
        @options = options
      end
      def getter_uri; raise NotImplementedError; end
      def fetch; raise NotImplementedError; end
      def parse(result); raise NotImplementedError; end

      def contacts
        result = parse fetch
        return result.to_yaml
      end
    end
  
    class Google < ContactApp
      def getter_uri
        done = CGI.escape @options[:done_uri]
        "https://www.google.com/accounts/AuthSubRequest?scope=http%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2F&session=1&secure=0&next=#{done}"
      end
      def fetch
        Net::HTTP.start("www.google.com") { |http|
          http.get("/m8/feeds/contacts/default/full",
            { 'Authorization' => "AuthSub token=\"#{@options[:token]}\"" }
          )
        }.body
      end
      def parse(contents)
        doc = Hpricot.XML(contents)
        entries = doc/:entry/"gd:email"
        entries.map { |e| e['address' ] }
      end
    end
  end
end

