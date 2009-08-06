#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'net/https'
require 'twitter'

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

module Twitter
  class Base
    def mentions(query={})
      perform_get('/statuses/mentions.json', :query => query)
    end
  end
end

def add_prowl(options)
  uri = URI.parse("https://prowl.weks.net/publicapi/add")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Post.new(uri.path)
  options = {:apikey => $configure[:prowl][:apikey], :application => "Twitter", :priority => 0}.merge(options)
  req.set_form_data(options)
  https.request(req)
end

def authorized_twitter
  oauth = Twitter::OAuth.new($configure[:twitter][:ctoken], $configure[:twitter][:csecret])
  unless($configure[:twitter][:atoken] && $configure[:twitter][:asecret])
    rtoken = oauth.request_token
    puts "Open next url, authorize this application: #{rtoken.authorize_url}"
    puts "Then, enter PIN code:"
    pin = STDIN.gets.chomp
    atoken = OAuth::RequestToken.new(oauth.consumer, rtoken.token, rtoken.secret).get_access_token(:oauth_verifier => pin)
    $configure[:twitter][:atoken] = atoken.token
    $configure[:twitter][:asecret] = atoken.secret
  end
  oauth.authorize_from_access($configure[:twitter][:atoken], $configure[:twitter][:asecret])
  Twitter::Base.new(oauth)
end

def last_id(key, id = nil)
  ids = $configure[:twitter][:last_ids] || {}
  current_id = ids[key]
  ids[key] = id if id
  $configure[:twitter][:last_ids] = ids;
  current_id
end

def mentions(twitter, options = {})
  if last_id = last_id(:mentions)
    options[:since_id] = last_id
  end
  mentions = twitter.mentions(options)
  last_id(:mentions, mentions.first.id) unless mentions.empty?
  mentions
end

def write_configure(config = nil)
  config ||= $configure
  File.open($configure_file, "w"){|f| YAML.dump(config, f)}
end

def main
  $configure_file = File.join(File.dirname(__FILE__), File.basename(__FILE__, ".*") + ".yml")
  begin
    $configure = $default_configure.merge(YAML.load_file($configure_file))
  rescue
    puts "Please edit #{$configure_file} for your environment"
    write_configure($default_configure)
    exit
  end

  twitter = authorized_twitter
  tweets = mentions(twitter)
  if tweets.length > 0
    if $configure[:prowl_per_tweet]
      ($configure[:max_prowl] == 0 ? tweet.length : $configure[:max_prowl]).times do
        tweet = tweets.shift
        break unless tweet
        add_prowl(:event => tweet.user.screen_name, :description => tweet.text + " http://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}")
      end
      unless tweets.empty?
        add_prowl(:event => "And more #{tweets.length} remains", :description => "http://twitter.com/")
      end
    else
      description = tweets.map do |tweet|
        "#{tweet.user.screen_name}: #{tweet.text} - http://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
      end.join("\n")
      add_prowl(:event => "#{tweets.length} tweets", :description => description)
    end
  end
end

main
