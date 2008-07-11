#!/usr/bin/ruby
# The plan is to be able to import contacts from a variety of places without
# using a password.
#
# For that an example.com website could tells its users to click on :
# http://tangram.example.com/contacts/yahoo?format=yml&return_to=http://example.com/return-url
#
# Tangram-contacts then takes the user by the hand, redirecting on the website,
# or finding the publicly avaible information and POSTs the result on the given
# return_to URI, in the given format (yml, xml, csv).
#
# To launch a development app, type:
#   ruby tangram-importer.rb
# Then try it out at:
#   http://localhost:4567/?return_to=http://localhost:4567/implementation-test

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
end


# GET /yahoo/done /google/done...
# called when returning with an auth token, will GET data, parse it and POST it back
get '/:app/done' do
  app = Tangram::ContactGetter.new_app(params)
  contacts = app.contacts
  
  # POSTs then redirects
  res = Net::HTTP.post_form(URI.parse(params[:return_to]),
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


