#!/usr/bin/ruby

require "rubygems"
require "sinatra"
require "haml"
require "activesupport"
require "cgi"

require File.dirname(__FILE__) + "/lib/tangram/contact-getter.rb"

CONTACTS_URI = "http://localhost:4567/"

# Index presenting the available contacts services
get '/' do
  raise ArgumentError, "missing the return_to parameter" if params[:return_to].blank?
  format = params[:format].blank? ? :yml : params[:format].to_sym
  raise ArgumentError, "no such format" unless Tangram::ContactGetter::FORMATS.has_key?(format)

  @apps = [:google]
  @return_to = 'return_to=' + CGI.escape(params[:return_to])
  haml :index
end


# Tests to see the data that finally gets POSTed
get "/implementation-test" do
  header 'Content-Type' => 'text/plain; charset=utf-8'
  open('/tmp/tangram.txt').read
end
post "/implementation-test" do
  open('/tmp/tangram.txt', 'w') do |f|
    f << params[:data]
  end
  "Done!"
end


# GET /yahoo/done /google/done...
# called when returning with an auth token, will GET data, parse it and POST it back
get '/:app/done' do
  app = Tangram::ContactGetter.new_app(params)
  contacts = app.contacts
  
  Net::HTTP.post_form(URI.parse(params[:return_to]),
    :format => params[:format], :data => contacts)

  redirect params[:return_to]
end

# GET /yahoo /google...
# redirects to the authorization page
get '/:app' do
  raise Sinatra::NotFound unless Tangram::ContactGetter.app_exists?(params[:app])
  raise ArgumentError, "missing the return_to parameter" if params[:return_to].blank?
  
  format = params[:format].blank? ? :yml : params[:format].to_sym
  raise ArgumentError, "no such format" unless Tangram::ContactGetter::FORMATS.has_key?(format)
  
  params[:done_uri] = "#{CONTACTS_URI}#{params[:app]}/done"
  params[:done_uri] += "?return_to=#{CGI.escape params[:return_to]}"
  params[:done_uri] += "&format=#{CGI.escape format.to_s}"
  
  app = Tangram::ContactGetter.new_app(params)
  redirect app.getter_uri
end


