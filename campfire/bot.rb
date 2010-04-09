$:.unshift "#{File.dirname(__FILE__)}/../vendor/tinder/lib"
require "rubygems"
require "tinder"

class Campfire
  class Bot
    attr_accessor :campfire, :room, :domain, :token, :name, :ssl, :debug

    def initialize(params = {})
      self.debug = params[:debug]
      self.ssl = params[:ssl]
      self.domain = params[:domain]
      self.token = params[:token]
      self.campfire = Tinder::Campfire.new(domain, :ssl => ssl, :token => token)
      self.name = campfire.me["name"]
      begin
        self.room = campfire.find_room_by_name(params[:room]) or raise "Could not find a room named '#{params[:room]}'"
      rescue Tinder::AuthenticationFailed => e
        raise # maybe do some friendlier error handling later
      end
      room.join
    end

    def base_uri
      campfire.connection.uri.to_s
    end
    
    # convenience method so I don't have to change all the old #say method to #speak
    def say(*args)
      room.speak(*args)
    end
    
    # pick something at random from an array of sayings
    def say_random(sayings)
      say(sayings[rand(sayings.size)])
    end
    
    # Proxy everything to the room.
    def method_missing(m, *args)
      room.send(m, *args)
    end
  end
end
