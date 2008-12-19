# plugin to send a tweet to a Twitter account
class ImageSearchPlugin < Campfire::PollingBot::Plugin
  priority 1
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /(?:photo|image|picture)\s+of\s*(?:a\s*)?:?\s*("?)(.*?)\1$/i
      subject = $2
      photo_links = query_flickr(subject)
      if photo_links.empty?
        bot.say("Couldn't find anything for \"#{subject}\"")
      else
        bot.say_random(photo_links)
      end
      return HALT
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['(photo|image|picture) of <subject>', "find a random picture on flickr of <subject>"]]
  end
  
  private
  
  # set up the http client
  def client
    unless @client
      proxy = (config && config['proxy']) || ENV['HTTP_PROXY']
      @client = HTTPClient.new(proxy)
    end
    return @client
  end
  
  # post a message to twitter
  def query_flickr(subject)
    query = "select * from flickr.photos.search where text=\"#{subject}\""
    res = client.get("http://query.yahooapis.com/v1/public/yql", :q => query, :format => 'json')
    return [] unless res.status == 200
    result = JSON.parse(res.content)
    return [] if result["query"]["count"] == "0"
    photos = result["query"]["results"]["photo"]
    #http://farm4.static.flickr.com/3016/2954249471_ed3f510a4e.jpg?v=0
    return photos.map {|p| "http://farm%s.static.flickr.com/%s/%s_%s.jpg?v=0" % [p['farm'], p['server'], p['id'], p['secret']]}
  end
end
