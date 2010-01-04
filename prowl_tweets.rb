#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'net/https'
require 'twitter'

# Default configuration
$default_configure = {
  :twitter => {
    :ctoken => "",
    :csecret => ""
  },
  :prowl => {
    :apikey => ""
  },
  :max_prowl => 5,
  :prowl_per_tweet => false
}

# Extend twitter.gem to get mentions using API
module Twitter
  class Base
    def mentions(query={})
      perform_get('/statuses/mentions.json', :query => query)
    end
  end
end

# Push a notification to Prowl
def add_prowl(options)
  uri = URI.parse("https://prowl.weks.net/publicapi/add")
  https = Net::HTTP.new(uri.host, uri.port)
  # We have to use SSL
  https.use_ssl = true
  # Avoid to get warning
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Post.new(uri.path)
  # Default options for notifications
  options = {:apikey => $configure[:prowl][:apikey], :application => "Twitter", :priority => 0}.merge(options)
  req.set_form_data(options)
  https.request(req)
end

# Create authorized Twitter client instance
def authorized_twitter
  oauth = Twitter::OAuth.new($configure[:twitter][:ctoken], $configure[:twitter][:csecret])
  # Request OAuth authentication if there are no access token yet
  unless($configure[:twitter][:atoken] && $configure[:twitter][:asecret])
    rtoken = oauth.request_token
    puts "Open next url, authorize this application: #{rtoken.authorize_url}"
    puts "Then, enter PIN code:"
    pin = STDIN.gets.chomp
    # Authrize request token using PIN code (this is required for an application which type is "Client")
    atoken = OAuth::RequestToken.new(oauth.consumer, rtoken.token, rtoken.secret).get_access_token(:oauth_verifier => pin)
    # Save access token
    $configure[:twitter][:atoken] = atoken.token
    $configure[:twitter][:asecret] = atoken.secret
  end
  oauth.authorize_from_access($configure[:twitter][:atoken], $configure[:twitter][:asecret])
  # Create Twitter client instance with OAuth
  Twitter::Base.new(oauth)
end

# Get last_id for specific key like mentions or public_timeline etc.
def last_id(key, id = nil)
  ids = $configure[:twitter][:last_ids] || {}
  current_id = ids[key]
  # Save last id if id is passed
  ids[key] = id if id
  $configure[:twitter][:last_ids] = ids;
  current_id
end

# Get mentions using Twitter client
def mentions(twitter, options = {})
  if last_id = last_id(:mentions)
    options[:since_id] = last_id
  end
  mentions = twitter.mentions(options)
  last_id(:mentions, mentions.first.id) unless mentions.empty?
  mentions
end

# Flash configure to a YAML file
def write_configure(config = nil)
  config ||= $configure
  File.open($configure_file, "w"){|f| YAML.dump(config, f)}
end

# Main
def main
  # Get configuration, if failed, prompt user to configure it.
  $configure_file = File.join(File.dirname(__FILE__), File.basename(__FILE__, ".*") + ".yml")
  begin
    $configure = $default_configure.merge(YAML.load_file($configure_file))
  rescue
    puts "Please edit #{$configure_file} for your environment"
    write_configure($default_configure)
    exit
  end

  # Get mention tweets
  twitter = authorized_twitter
  tweets = mentions(twitter)
  if tweets.length > 0
    # Push notification(s) to Prowl
    if $configure[:prowl_per_tweet]
      ($configure[:max_prowl] == 0 ? tweet.length : $configure[:max_prowl]).times do
        tweet = tweets.shift
        break unless tweet
        add_prowl(:event => tweet.user.screen_name, :description => tweet.text + " tweetie://status?id=#{tweet.id}")
      end
      unless tweets.empty?
        add_prowl(:event => "And more #{tweets.length} remains", :description => "tweetie://")
      end
    else
      description = tweets.map do |tweet|
        "#{tweet.user.screen_name}: #{tweet.text} - tweetie://status?id=#{tweet.id}"
      end.join("\n")
      add_prowl(:event => "#{tweets.length} tweets", :description => description)
    end
  end
end

main
