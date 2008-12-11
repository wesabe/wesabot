# Plugin to provide a summary (via paste) of al activity since you last logged out
# requires the HistoryPlugin
class BacklogPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true  
  
  # ignore messages from these users
  IGNORE_USERS = %w{Fogbugz Subversion GeneralZod Capistrano}
  
  def process(message)
    if message.command.match(/backlog/)
      if backlog = get_backlog(message.person_full_name, message.person)
        bot.say("Here you go, #{message.person}:")
        bot.paste(backlog)
      else
        bot.say("Are you kidding me?")
      end
      return HALT
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['backlog', 'display (as a paste) a summary of all activity since you last logged out']]
  end
    
  private
  
  # get the backlog since the user last left the room. Filter out all the FB, Subversion, and Zod crap
  def get_backlog(person_full_name, requester)
    last_left = Message.first(
      :conditions => {:person => person_full_name, :message_type => ['Leave','Kick']},
      :order => [:timestamp.desc])
    
    if last_left  
      # if person timed out, look for their last entry before the timeout
      if last_left.message_type == 'Kick'
        last_left = Message.first(
          :conditions => {:person => person_full_name, :timestamp.lt => last_left.timestamp},
          :order => [:timestamp.desc])
      end

      # get all text messages since they left
      history = Message.all(
        :conditions => { :timestamp.gt => last_left.timestamp,
                         :person.not => IGNORE_USERS,
                         :message_type => 'Text' },
        :order => [:timestamp])
      messages = history.map { |m| "#{m.person}: #{m.body}" }
    
      return messages.join("\n")
    end
  end  
end