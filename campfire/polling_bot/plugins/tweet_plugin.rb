# plugin to send a tweet to a Twitter account
class TweetPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true

  def process(message)
    case message.command
    when /^(?:tweet|twitter):?\s*("?)(.*?)\1$/i
      begin
        text = strip_links($2)
        post_tweet(text)
      rescue TwitterError => ex
        bot.say("Hmm...didn't work. Got this response:")
        bot.paste(ex.http_result.content)
      end
      return HALT
    when /^(?:save|queue)\s+(?:tweet|twitter):?\s*("?)(.*?)\1$/i
      tweet = Tweet.create(:person => message.person, :message => strip_links($2), :timestamp => message.timestamp.to_i)
      bot.say("Ok, saved for later: #{tweet}")
      return HALT
    when /^(?:show|list)\s+(?:all\s+)?(?:queued\s+)?(?:tweets|twitters)$/i
      act_on_list do |list|
        bot.say("Here are the tweets in the queue:")
        i = 0
        bot.paste(list.map{|tweet| "#{i+=1}. #{tweet}"}.join("\n"))
      end
      return HALT
    when /^show\s+next\s+(?:tweet|twitter)$/i
      act_on_list do |list|
        bot.say("Next tweet to post: #{list.first}")
      end
      return HALT
    when /^(post|send)\s+next\s+(?:tweet|twitter)$/i
      act_on_list do |list|
        tweet = list.first
        post_tweet(tweet)
        tweet.destroy
      end
      return HALT
    when /^(post|send)\s+tweet\s+(\d+)$/i
      act_on_tweet($1.to_i-1) do |tweet|
        post_tweet(tweet)
        tweet.destroy
      end
      return HALT
    when /^delete\s+tweet\s+(\d+)$/i
      act_on_tweet($1.to_i-1) do |tweet|
        tweet.destroy
        bot.say("Okay, deleted tweet #{$1}: #{tweet}")
      end
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [['tweet: <message>', "post <message> to #{config['username']}'s twitter account"],
     ['save tweet: <message>', "save <message> for later"],
     ['show tweets', "shows the queued tweets for #{config['username']}'s twitter account"],
     ['show next tweet', "shows the oldest queued twitter message"],
     ['post next tweet', "sends the oldest queued twitter message"],
     ['post tweet <n>', "sends the <n>th tweet from the list"],
     ['delete tweet <n>', "deletes the <n>th tweet from the list"]]
  end

  private

  def post_tweet(tweet)
    begin
      Tweet.tweet(tweet.to_s, config['username'], config['password'], config['proxy'])
      bot.say("Ok, tweeted: #{tweet}")
    rescue Tweet::TwitterError => ex
      bot.say("Hmm...didn't work. Got this response:")
      bot.paste(ex.http_result.content)
    end
  end

  def act_on_list
    list = Tweet.list
    if list.empty?
      bot.say("There are no queued tweets.")
    else
      yield list
    end
  end

  def act_on_tweet(n)
    if tweet = Tweet.list[n]
      yield tweet
    else
      bot.say("Could not find tweet #{n}")
    end
  end

  # strip links from CF messages
  def strip_links(msg)
    msg.gsub(/<a href="([^"]*)".*?>.*?<\/a>/, '\1')
  end
end
