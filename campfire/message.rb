# Classes to encapsulate the various campfire message types
require 'cgi'

class Campfire
  # base message class. All messages have a message_id, timestamp, person (first name of the user generating
  # the message), person_full_name (first name + last initial of the user generating the message (TODO: instead
  # grab the user's actual full name from the sidebar)), and body, which is the text of the message
  class Message
    attr_accessor :message_id, :timestamp, :person, :person_full_name, :body
  
    def initialize(params)
      self.message_id = params[:message_id]
      self.timestamp = params[:timestamp] || Time.now
      self.person_full_name = params[:person]
      self.person = person_full_name.split(' ')[0] # just get first name
      self.body =  CGI.unescapeHTML(params[:body]) if params[:body]
    end
  end
  
  # TextMessage - normal user text message
  #   #command - if the message is addressed to the bot ("<bot name>, ..." or "..., <bot name>"), the
  #  the part of the body minus the bot name (and comma) is returned by #command
  class TextMessage < Message
    attr_accessor :command
  end

  # a PasteMessage is sent when a paste block appears. #link contains the link to the full text of the
  # pasted block (TODO: grab the full paste from the link and have it available)
  class PasteMessage < Message
    attr_accessor :link
  
    def initialize(params)
      super
      self.link = params[:link]
    end  
  end
  
  # an UploadMessage is sent when a user uploads a file. #link contains the link to the file
  class UploadMessage < Message
    attr_accessor :link
  
    def initialize(params)
      super
      self.link = params[:link]
    end  
  end

  # EnterMessage - sent when a user enters the room
  class EnterMessage < Message; end

  # LeaveMessage - sent when a user leaves the room
  class LeaveMessage < Message; end
  
  # KickMessage - sent when a user times out and is booted from the room
  class KickMessage < Message; end
  
  # LockMessage - sent when a user locks the room
  class LockMessage < Message; end
  
  # UnlockMessage - sent when the room is unlocked
  class UnlockMessage < Message; end
  
  # AllowGuestsMessage - sent when guest access is turned on
  class AllowGuestsMessage < Message; end

  # DisallowGuestsMessage - sent when guest access is turned off
  class DisallowGuestsMessage < Message; end

  # TopicChangeMessage - sent when the room's topic is changed
  class TopicChangeMessage < Message; end
  
  # TimestampMessage - sent when a timestamp is posted to the room
  class TimestampMessage < Message; end
  
  # AdvertisementMessage - ads
  class AdvertisementMessage < Message; end
end