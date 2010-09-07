require 'rubygems'
require 'yaml'
require 'twitter'
require 'logger'
require File.join(File.dirname(__FILE__), 'thesaurus')
require File.join(File.dirname(__FILE__), 'wordnik_service')


class Twisaurus
  
  GREETING = "Hi %s! Look up synonyms by sending me a PM with a word of your choice, i.e.: word [verb, noun, adjective, adverb]"
  
  attr_reader :twitter, :last_message_retrieved
  
  def initialize
    @config = YAML.load(File.open("config/bot.yml"))
    oauth = Twitter::OAuth.new(@config['consumer_token'], @config['consumer_secret'])
    oauth.authorize_from_access(@config['access_token'], @config['access_secret'])

    @twitter = Twitter::Base.new(oauth)
    @last_message_retrieved = nil
  end


  def run
    max = @config['max_interval'] #300
    step = @config['interval_step'] #10
    interval = @config['min_interval'] #120
    
    loop do
      log.info "Entered loop at #{Time.now}"
      updates = 0
      updates += to_follow.length
      updates += check_for_new_messages
      
      #interval increments if there are no updates
      interval = updates > 0 ? @config['min_interval'] : [interval + step, max].min
      
      auto_follow if !to_follow.empty?
      reply if @num_messages > 0
      
      log.debug "Bot sleeping for #{interval}s"
      sleep interval
    end
  end

  def to_follow
    twitter.follower_ids - twitter.friend_ids
  end
  
  # helper method to avoid hitting the API more than necessary when checking whether there are any messages
  # also: set processed[:message] to the ID of the most recent message, so we avoid later on picking up the 
  # same message twice
  def check_for_new_messages
    messages = twitter.direct_messages(:since_id => last_message_retrieved)
    @num_messages = messages.length
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
    log.debug "IN REPLY: last message ID is: #{last_message_retrieved}"
    options = {}
    options[:since_id] = last_message_retrieved
    # needs to reversed, because first item in array is latest message
    messages = twitter.direct_messages(options).reverse
    messages.each do |dm|
      log.info "Received PM from #{dm.sender_screen_name}: #{dm.text}"
      t = Thesaurus.new(WordnikService.new)
      answer = t.lookup_synonyms(dm.text)
      log.info "Answer was #{answer}"
      # send DM with answer
      twitter.direct_message_create(dm.sender_id, answer)
      # reset last message ID
      @last_message_retrieved = dm.id
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

