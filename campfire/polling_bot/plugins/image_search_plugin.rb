# plugin to send a tweet to a Twitter account
class ImageSearchPlugin < Campfire::PollingBot::Plugin
  priority 1
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /(?:photo|image|picture)\s+of:?\s+(?:a:?\s+)?\s*("?)(.*?)\1$/i
      subject = $2
      if photo_links = query_flickr(subject)
        if photo_links.empty?
          bot.say("Couldn't find anything for \"#{subject}\"")
        else
          bot.say_random(photo_links)
        end
      end
      return HALT
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['(photo|image|picture) of <subject>', "find a random picture on flickr of <subject>"]]
  end
  
  private
  
  # post a message to twitter
  def query_flickr(subject)
    # URI.encode shouldn't be necessary, but datamapper's extlib implements Hash#to_params incorrectly
    query = URI.encode("select * from flickr.photos.search where text=\"#{subject}\"")
    options = { :query => {:q => query, :format => 'json'} }
    if proxy = (config && config['proxy']) || ENV['HTTP_PROXY']
      proxy_uri = URI.parse(proxy)
      options.update(:http_proxyaddr => proxy_uri.host, :http_proxyport => proxy_uri.port)
    end
    response = HTTParty.get("http://query.yahooapis.com/v1/public/yql", options)
    case response.code
    when 200
      return [] if response["query"]["count"] == "0"
      photos = response["query"]["results"]["photo"]
      photos = [photos] if photos.is_a?(Hash)
      return photos.map {|p| "http://farm%s.static.flickr.com/%s/%s_%s.jpg?v=0" % [p['farm'], p['server'], p['id'], p['secret']]}
    when 403
      bot.say("Sorry, we seem to have hit our query limit for the day.")
    else
      bot.say("Hmm...didn't work. Got this response:")
      bot.paste(response.body)      
    end
  end
end
