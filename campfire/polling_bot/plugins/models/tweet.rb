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
  property :message,   String, :nullable => false
  property :person,    String
  property :timestamp, Integer, :nullable => false

  def tweet(user, pass, proxy=nil)
    self.class.tweet(message, user, pass, proxy)
  end

  def self.tweet(message, user, pass, proxy=nil)
    result = post(message, user, pass, proxy)
    if result.status == 200
      return true
    else
      raise TwitterErrror.new(result)
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
    client(user, pass, proxy).post("http://twitter.com/statuses/update.xml", :status => message)
  end

  # set up the http client
  def self.client(user, pass, proxy=nil)
    proxy ||= ENV['HTTP_PROXY']

    @clients ||= {}
    @clients["#{user}:#{pass}:#{proxy}"] ||= begin
      client = HTTPClient.new(proxy)
      client.set_auth("http://twitter.com", user, pass)
      client
    end
  end
end
