
*NOTE:* Development has moved over to [http://github.com/hackarts/wesabot]()

Wesabot
=======

Wesabot, the Campfire bot framework.

Description
-----------
Wesabot is a Campfire bot framework we've been using and developing at Wesabe since not long after our inception. It started as a way to avoid parking tickets near our office ("Wes, remind me in 2 hours to move my car"), and has evolved into an essential work aid. When you enter the room, Wes greets you with a link to the point in the transcript where you last left. You can also ask him to bookmark points in the transcript, send an sms message (well, an email) to someone, or even post a tweet, among other things. His functionality is easily extendable via plugins.

To give Wes new powers, simply drop a plugin file in the plugins directory and restart Wes (or, via the ReloadPlugin, he can be told to reload himself). See `campfire/polling_bot/sample_plugin.rb` for more information, or just browse the included plugins. Some of the plugins are somewhat Wesabe-specific (like DeployPlugin, which lets us see what commits are on deck to be deployed), but can be adapted or ignored as you see fit.

If any of your plugins need to use a database, just drop a Datamapper model in the plugins/models directory and it will be automatically loaded.

Installation
------------

You'll need SQLite3 installed (http://www.sqlite.org/), and a number of gems:

    sudo gem install dm-core do_sqlite3 activesupport httparty mime-types chronic

Then copy `wesabot-sample.rb` to `wesabot.rb` and add your Campfire credentials.

Once Wes (or whatever you decide to name your bot) is running, you can see a list of available commands by entering into Campfire:

    Wes, help

That list currently looks like:


    BacklogPlugin:
     - backlog
         display (as a paste) a summary of all activity since you last logged out

    BookmarkPlugin:
     - bookmark: <name>
         bookmark the current location

    DeployPlugin:
     - what's on deck?
         get shortlog of to-be-deployed changes for pfc
     - what's on deck for <project>?
         get the shortlog of to-be-deployed changes for a specific project

    GreetingPlugin:
     - (disable|turn off) greetings
         don't say hi when you log in (you grump)
     - (enable|turn on) greetings
         say hi when you log in
     - toggle greetings
         disable greetings if enabled, enable if disabled. You know--toggle.
     - catch me up|ketchup
         gives you a link to the point in the transcript where you last logged out

    HelpPlugin:
     - help
         this message

    ImageSearchPlugin:
     - (photo|image|picture) of <subject>
         find a random picture on flickr of <subject>

    ReloadPlugin:
     - reload
         update and reload Wes

    RemindMePlugin:
     - remind (me|<person>) [in] <time string> to <message>
         set up a reminder
     - remind (me|<person>) to <message> (in|on|at|next|this) <time string>
         set up a reminder
     - [list|show] [person]['s] reminders
         display current reminders for yourself or person
     - delete reminder <n>
         delete your reminder #n

    SMSPlugin:
     - set my sms address to: <address>
         set your sms address
     - set <person>'s sms address to
         set someone else's sms address
     - (sms|text|txt) <person>: <message>
         send an sms message
     - list sms addresses
         list all sms addresses

    StatusPlugin:
     - set my status to: <status>
         set your status
     - show <person>'s status
         show the status for <person>
     - list all statuses
         show the statuses for everyone
     - what's <person> up to?
         show the status for <person> -- works without addressing me

    TimePlugin:
     - time
         say the current time

    TweetPlugin:
     - tweet: <message>
         post <message> to a twitter account
     - save tweet: <message>
         save <message> for later
     - show tweets
         shows the queued tweets for a twitter account
     - show next tweet
         shows the oldest queued twitter message
     - post next tweet
         sends the oldest queued twitter message
     - post tweet <n>
         sends the <n>th tweet from the list
     - delete tweet <n>
         deletes the <n>th tweet from the list
