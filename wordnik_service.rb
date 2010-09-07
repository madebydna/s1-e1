require 'rubygems'
require 'yaml'
require 'httparty'

class WordnikService
  include HTTParty
  
  base_uri 'http://api.wordnik.com/api'
  
  def initialize
    @api_key = YAML.load(File.open("config/bot.yml"))['wordnik_api_key']
  end 
  
  def do_request(request, options)
    options = options.merge(:api_key => @api_key)
    self.class.get("/#{request}?#{create_query_string(options)}")
  end 
  
  
  private
  
  def create_query_string(params)
    params.keys.inject('') do |query_string, key|
      query_string << '&' unless key == params.keys.first
      query_string << "#{URI.encode(key.to_s)}=#{URI.encode(params[key])}"
    end 
  end
end

  
  