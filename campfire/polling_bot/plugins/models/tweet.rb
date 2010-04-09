# used by TweetPlugin
class Tweet
  class TwitterError < RuntimeError
    attr_reader :http_result

    def initialize(http_result)
      @http_result = http_result
    end
  end

  include DataMapper::Resource
  property :id,        Serial
  property :message,   String, :required => true
  property :person,    String
  property :timestamp, Integer, :required => true

  def tweet(user, pass, proxy=nil)
    self.class.tweet(message, user, pass, proxy)
  end

  def self.tweet(message, user, pass, proxy=nil)
    result = post(message, user, pass, proxy)
    if result.code == 200
      return true
    else
      raise TwitterError.new(result.body)
    end
  end

  def self.list
    all(:order => [:timestamp.asc])
  end

  def to_s
    message
  end

  private

  # post a message to twitter
  def self.post(message, user, pass, proxy=nil)
    options = { 
      :query => {:status => message}, 
      :basic_auth => {:username => user, :password => pass} 
    }
    if proxy ||= ENV['HTTP_PROXY'] 
      proxy_uri = URI.parse(proxy)
      options.update(:http_proxyaddr => proxy_uri.host, :http_proxyport => proxy_uri.port)
    end
    HTTParty.post("http://twitter.com/statuses/update.xml", options)
  end
end
