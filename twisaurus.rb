require 'rubygems'
require 'yaml'
require 'twitter'
require 'logger'
require File.join(File.dirname(__FILE__), 'thesaurus')
require File.join(File.dirname(__FILE__), 'wordnik_service')


class Twisaurus
  
  GREETING = "Hi %s! Look up synonyms by sending me a PM with a word of your choice, i.e.: word [verb, noun, adjective, adverb]"
  
  attr_reader :twitter
  
  def initialize
    @config = YAML.load(File.open("config/bot.yml"))
    oauth = Twitter::OAuth.new(@config['consumer_token'], @config['consumer_secret'])
    oauth.authorize_from_access(@config['access_token'], @config['access_secret'])

    @twitter = Twitter::Base.new(oauth)
  end

  def run
    max = @config['max_interval'] #300
    step = @config['interval_step'] #10
    interval = @config['min_interval'] #120
    
    loop do
      log.info "Entered loop at #{Time.now}"
      updates = 0
      updates += to_follow.length
      updates += twitter.direct_messages.length
      
      #interval increments if there are no updates
      interval = updates > 0 ? @config['min_interval'] : [interval + step, max].min
      
      auto_follow if !to_follow.empty?
      reply if twitter.direct_messages
      log.debug "Bot sleeping for #{interval}s"
      sleep interval
    end
  end

  def to_follow
    twitter.follower_ids - twitter.friend_ids
  end
  
  def auto_follow
    to_follow.each do |f|
      user = twitter.user(f)
      log.info "Started following #{user.name} - http://twitter.com/#{user.screen_name}"
      twitter.friendship_create user.screen_name
      twitter.direct_message_create(user.screen_name, sprintf(GREETING, user.screen_name))
    end
  end


  def reply
    # for responding to DM
    twitter.direct_messages.each do |dm|
      log.info "Received PM from #{dm.sender_screen_name}: #{dm.text}"
      t = Thesaurus.new(WordnikService.new)
      answer = t.lookup_synonyms(dm.text)
      log.info "Answer was #{answer}"
      # send DM with answer
      twitter.direct_message_create(dm.sender_id, answer)
      # delete DM
      twitter.direct_message_destroy(dm.id)
    end
  end
  
  # Return logger instance
  def log
    return @log if @log
    file = File.open("log/app.log", "a")
    @log = Logger.new(file)
    #@log.level = Logger.const_get("INFO")
    @log
  end
  
end

t = Twisaurus.new
t.run

