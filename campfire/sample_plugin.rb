# Sample Campfire plugin. Plugins must be placed in the plugins directory in order to be loaded.
class SamplePlugin < Campfire::PollingBot::Plugin
  # accept - specify which kinds of messages this plugin accepts. Put each type on its own line.
  # You may optionally set :addressed_to_me => true to get only messages addressed to the bot.
  # For example,
  #   accept :text_message, :addressed_to_me => true
  # Will only accept text messages that are in the form "<bot name>, ..." or "... <bot name>".
  # The body of the message minus the bot name will be returned by the 'command' method of the
  # message.
  #
  # Message types are:
  #  - :all - all messages
  #  - :text_message - normal user text message
  #  - :paste_message - a paste
  #  - :enter_message - sent when a user enters the room
  #  - :leave_message - sent when a user leaves the room
  #  - :kick_message - sent when a user times out from inactivity
  #  - :lock_message - sent when the room is locked
  #  - :unlock_message - sent when the room is unlocked
  #  - :allow_guests_message - sent when guest access is turned on
  #  - :disallow_guests_message - sent when guest access is turned off
  #  - :topic_change_message - sent when the room's topic is changed

  accept :text_message, :addressed_to_me => true
  accept :paste_message
  
  # priority is used to determine the plugin's order in the plugin queue. A higher number represents
  # a higher priority. There are no upper or lower bounds. If you don't specify a priority, it defaults
  # to 0.
  
  priority 10
  
  # If you need to do any one-time setup when the plugin is initially loaded, do it here. Optional. 
  def initialize
  end
  
  # If your plugin implements the heartbeat method, it will be called every time the bot polls the room
  # for activity (currently every 3 seconds), whether or not there are any new messages. The heartbeat
  # method is optional. It does not take any parameters.
  def heartbeat
  end
  
  # process is the only method your plugin needs to implement. This is called by the bot whenever it
  # has a new message that matches one of the message types accepted by the plugin. See Campfire::Message
  # for message documentation.
  # If no other plugins should receive the message after this plugin, return HALT.
  def process(message)
  end
  
  # help is actually functionality provided by another plugin, HelpPlugin. Just return an array of
  # ['command', 'description'] tuples
  def help
    [['some command', 'description of some command'],
     ['some other command', 'description of some other command']]
  end
end