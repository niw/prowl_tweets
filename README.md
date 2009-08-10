Prowl client for Twitter
========================

This is a tiny ruby script which fetch reply(mention) tweets from Twitter then push them to [Prowl](http://prowl.weks.net/).
This script must be a good example code for using Twitter, OAuth and Prowl APIs via Ruby script.

Install
-------
This script requires [twitter.gem](http://twitter.rubyforge.org/). Please install it by next commend.
Also, you need to install [rubygems](http://rubygems.org/) prior to install.

    % gem install twitter

After installing required gem, once run next command to generate initial configuration file.

    % ruby prowl_tweets.rb

You'll get prowl_tweets.yml in same dir of this script file.
Open prowl_tweets.yml then put next keys for using Twitter and Prowl APIs.

    --- 
    :twitter: 
      :ctoken: (Consumer key for Twitter API)
      :csecret: (Consumer secret for Twitter API)
    :prowl: 
      :apikey: (Prowl API key)
    :max_prowl: 5
    :prowl_per_tweet: false

 *  ctoken and csecret

    You can get them from [Twitter OAuth page](http://twitter.com/oauth_clients)(Requre login.)
	When you are registering the OAuth client, you have to select "Application Type" as "Client".
	"Default Access type" is enough as "Read-only".

 *  apikey

    You can get it from Settings page on [Prowl website](http://prowl.weks.net/).
	You have to login to request new API key.

 *  prowl_per_tweet and max_prowl

    `true` or `false` is accepted. when you set it as true, the script may push one prowl notification per one tweet. Otherwise, this script push a single notificatoin includes all new tweets in text.
    If this value equals `true`, we can limit the number of prowl notifications by `max_prowl` value.

After configuring it, you need to login to Twitter via OAuth. Just running this script by next command again.

    % ruby prowl_tweets.rb

At first time, you'll get the prompt with OAuth authentication URL.
Open that URL then allow to access and grab PIN code.
Then put the PIN code, press Enter key.

Usage
-----

When you complete the installation, you can get one or more notification by running this script by next command.

    % ruby prowl_tweets.rb

If you want to use it as a persistent notification program, you have to use cron or something like to enable to run this command in some interval.
