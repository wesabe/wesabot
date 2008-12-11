require 'campfire/client'

class Campfire
  class Bot
    attr_accessor :client
    attr_accessor :debug
    attr_accessor :name
    
    def initialize(params = {})
      # if the name of the bot isn't provided, use the first part of the email address
      self.name = params[:name] || params[:username].gsub('@.*','')
      self.debug = params[:debug]
      self.client = Client.new(:domain => params[:domain], :ssl => params[:ssl], :debug => debug)
      client.login(:username => params[:username], :password => params[:password], :room => params[:room])
    end

    # Proxy everything to the client.
    def method_missing(m, *args)
      client.send(m, *args)
    end
  end
end