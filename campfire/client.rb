# Campfire Client.
# Adapted from Marshmallow, the campfire chatbot
#
# You need to know one the following:
#  (a) the secret public URL, or
#  (b) an account/password for your room and the room number.
#
# Usage:
#   to login with a password:
#
#   bot = Campfire::Client.new( :domain => 'mydomain', :ssl => true )
#   bot.login :username  => "yourbot@email.com",
#     :password => "passw0rd",
#     :room     => "11234"
#   bot.say("So many ponies in here! I want one!")
#
#  to use the public url:
#
#    bot = Campfire::Client.new( :domain => 'mydomain' )
#    bot.login( :url => 'aDxf3' )
#    bot.say "Ponies!!"
#    bot.paste "<script type='text/javascript'>\nalert('Ponies!')\n</script>"
#

require 'rubygems'
require 'httpclient'
require 'hpricot'
require 'json'
require 'campfire/message'

class Campfire
  class Client
    VERSION = '3.0'
    attr_accessor :domain, :base_uri, :room

    USER_AGENT = "Mozilla/5.0 Wesabot/#{VERSION}"
    CLIENT_RETRIES = 12 # how many times to retry a get/post operation until we fail

    def initialize(options={})
      @debug  = options[:debug]
      @domain = options[:domain] || @@domain
      @ssl    = options[:ssl]
      @base_uri = "http#{'s' if @ssl}://#{@domain}.campfirenow.com"
      user_agent = options[:user_agent] || USER_AGENT
      proxy = options[:proxy] || ENV['HTTP_PROXY']

      @client = HTTPClient.new(proxy, user_agent)
      
      if @ssl
        @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        # for some reason, even though we're not verifying, we stil need to set a local certificate if we
        # want to avoid a "unable to get local issuer certificate" warning with every connection
        @client.ssl_config.set_trust_ca(File.dirname(__FILE__) + '/GoDaddyCertificateAuthority.cer')
      end
    end

    # login to a room
    def login(options)
      # if a 'url' (actually, just the code from the end of a guest url) is provided, log into that room
      if options[:url]
        res = post("#{@base_uri}/#{options[:url]}", :name => options[:username])
        # parse our response headers for the room number.. magic!
        @room = res.header['location'][0].scan(/room\/(\d+)/).to_s
        puts "Logged in to room #{@room}" if @debug
      else
        @room   = options[:room]
        puts "Logging in..." if @debug
        post(@base_uri + "/login/",
          {:email_address => options[:username],
           :password => options[:password]},
          {'Content-Type' => 'application/x-www-form-urlencoded'})
      end
      say("Hello.")
    end

    # leave the room
    def leave_room
      puts "Leaving room #{@room}..." if @debug
      post(@base_uri + "/room/#{@room}/leave")
      @membership_key = nil
    end

    # call this regularly to keep from going idle and being timed out
    def keep_alive
      post(@base_uri + "/room/#{@room}/tabs")
    end

    # paste a multiline message into campfire
    def paste(message)
      say_one(message, true)
    end

    # Extend say to work with multiple lines.
    def say(message)
      message.split("\n").each{ |line| say_one(line) }
    end

    # original say method to say one line or paste
    def say_one(message, paste=false)
      puts "Posting #{message}" if @debug
      params = { :message => message.to_s }
      params[:paste] = paste if paste
      post_content(@base_uri + "/room/#{@room}/speak", params)
    end

    # pick something at random from an array of sayings
    def say_random(sayings)
      say(sayings[rand(sayings.size)])
    end

    # scan the room for new messages. only get messages after the given message_id, if provided
    def poll(starting_message_id = nil)
      # if we haven't joined the room yet, do so
      # we need to be in the room to be able to use the same polling cgi that ajax uses
      unless @membership_key
        puts "Joining room #{@room}" if @debug
        room_content = get_content(@base_uri + "/room/#{@room}")
        if m = room_content.match(/new Campfire\.Chat\((.*?)\);/)
          chat_data = m[1]
          m = chat_data.match(/"?membershipKey"?\s*:\s*"(.*?)"/)
          @membership_key = m[1]
          m = chat_data.match(/"?lastCacheID"?\s*:\s*(\d+)/)
          @last_cache_id = m[1]
          m = chat_data.match(/"?timestamp"?\s*:\s*(\d+)/)
          @server_timestamp = m[1]
        end
      end

      # get latest messages
      url = @base_uri + "/poll.fcgi"
      t = Time.now
      time_in_msec = t.to_i*1000 + t.usec/1000
      begin
        content = post_content(url,
          :m => @membership_key,
          :l => @last_cache_id,
          :s => @server_timestamp,
          :t => time_in_msec)
      rescue Exception => e
        puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        return []
      end

      # unescape content for Hpricot
      html = ''
      content.scan(/chat\.transcript\.queueMessage\((".*?"),\s+\d+\);/) do |body|
        html << JSON.parse('[' + body.first + ']').first
      end
      # parse out messages
      doc = Hpricot(html)
      messages = []
      doc.search("tr.message").each do |row|
        message_id = row.attributes["id"].match(/\d+$/)[0].to_i
        message_type = row.attributes["class"].match(/(\w+?)_message/)[1]

        next if starting_message_id && (message_id <= starting_message_id)
        begin
          klass = Campfire.const_get(message_type.camel_case + "Message")
          # for some message types, the person's name is sometimes wrapped in a span
          person_node = row.search("td.person")
          if (span = person_node.search("span")).any?
            person = span.inner_html
          else
            person = person_node.inner_html
          end
          body_node = row.search("td.body div")
          base_params = { :message_id => message_id, :person => person }

          message = case message_type
            when 'enter', 'leave', 'kick', 'lock', 'unlock', 'allow_guests', 'disallow_guests', 'text'
              klass.new(base_params.merge(:body => body_node.inner_html))
            when 'paste'
              klass.new(base_params.merge(:link => body_node.search("a").first.attributes["href"],
                                          :body => body_node.search("pre code").inner_html))
            when 'upload'
              klass.new(base_params.merge(:link => body_node.search("a").first.attributes["href"],
                                          :body => body_node.search("a").first.inner_html))
            when 'topic_change'
              klass.new(base_params.merge(:body => body_node.search("em").inner_html))
            end
        rescue Exception => e
          puts "Exception parsing #{message_type} message."
          puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          puts "Body:"
          puts row.inspect
        end

        if message
          message.timestamp = Time.now
          messages << message
        end
      end

      # get last cache id
      if messages.any? && m = content.match(/\.lastCacheID\s*=\s*(\d+)/)
        @last_cache_id = m[1]
      end

      return messages
    end

    private

    # wrap post/get methods so we can catch spurious SSL "bad write retry" errors and retry
    # (ruby's openssl library seems to be incomplete/buggy...that or there's something I'm missing,
    # which is not unlikely)
    def post(*params) #:nodoc:
      client_call(:post, *params)
    end

    def get(*params) #:nodoc:
      client_call(:get, *params)
    end

    def post_content(*params) #:nodoc:
      client_call(:post_content, *params)
    end

    def get_content(*params) #:nodoc:
      client_call(:get_content, *params)
    end

    def client_call(method, *params) #:nodoc:
      retry_count = 0
      while retry_count < CLIENT_RETRIES
        begin
          result = @client.send(method, *params)
          break
        rescue OpenSSL::SSL::SSLError, Timeout::Error => e
          puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          puts "Sleeping for #{2**retry_count} seconds and then retrying..."
          sleep 2 ** retry_count # back off retries in case CF is really down
          retry_count += 1
        end
      end
      return result
    end
  end
end
