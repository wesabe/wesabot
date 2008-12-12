# plugin to send a tweet to a Twitter account
class TweetPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /^(?:tweet|twitter):?\s*("?)(.*?)\1$/i
      msg = strip_links($2)
      send(msg)
      bot.say("Ok, tweeted: #{msg}")
      return HALT
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['(tweet|twitter): <message>', "post <message> to #{config['username']}'s twitter account"]]
  end
  
  private
  
  # set up the http client
  def client
    unless @client
      proxy = config['proxy'] || ENV['HTTP_PROXY']
      @client = HTTPClient.new(proxy)
      @client.set_auth("http://twitter.com", config['username'], config['password'])
    end
    return @client
  end
  
  # strip links from CF messages
  def strip_links(msg)
    msg.gsub(/<a href="(.*?)">.*?<\/a>/, '\1')
  end
  
  # post a message to twitter
  def send(msg)
    client.post("http://twitter.com/statuses/update.xml", :status => msg)
  end
end
