# Reminders plugin
require 'chronic'
class RemindMePlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  priority 10
  
  NUMBER_WORDS = %w{zero one two three four five six seven eight nine ten}
  def process(message)
    case message.command
    when /remind\s+(.*?)\s+(in\s+(\S+)\s+(?:seconds|minutes|hours|days|weeks|years))\s+to\s+(.*)/i
      reminder_person = $1
      time_string = $2
      time_value = $3
      action = $4
      if i = NUMBER_WORDS.index(time_value.downcase)    
        time_string.sub!(time_value, i.to_s)     
      end
    when /remind\s+(.*?)\s+to\s+(.*?)\s+((?:in|on|at|next|this).*)/i
      reminder_person = $1
      action = $2
      time_string = $3
    when /remind\s+(.*?)\s+(.*?)\s+to\s+(.*)/i
      reminder_person = $1
      time_string = $2
      action = $3
    when /(?:list|show) (\S+) reminders/i, /(?:list|show) reminders for (\S+)/i
      list_reminders(message.person, $1)
      return HALT
    when /(list|show) reminders$/
      list_reminders(message.person, message.person)
      return HALT
    when /delete reminder (?:#\s*)?(\d+)/
      delete_reminder(message.person, $1.to_i)
      return HALT
    else
      return
    end
   
    action.gsub!(/\bmy\b/i,'your')
    action.gsub!(/\bI\b/i,'you')
    
    begin
      time = Chronic.parse(time_string.sub(/^at/, ''))
    rescue RangeError
      bot.say("Whatever, #{message.person}.")
      return HALT
    end
    
    if !time || time.kind_of?(Chronic::Span)
      bot.say("sorry, #{message.person}, but I don't know what '#{time_string}' means.")
      return HALT
    end
    
    if reminder_person.downcase == 'me'
      reminder_person = message.person      
    else
      reminder_person.gsub!(/^(\w)/) {$1.upcase}
    end
    
    Reminder.create(:person => reminder_person, :action => action, :reminder_time => time)
    time_now = Time.now
    if [time.year,time.month,time.day] == [time_now.year,time_now.month,time_now.day]
      converted_time_string = time.strftime('%I:%M %p').gsub(/^0/,'')
    else
      converted_time_string = time.strftime('%c')
    end
    
    bot.say("ok, #{message.person}, I will remind #{reminder_person == message.person ? 'you' : reminder_person} #{time_string} (#{converted_time_string}) to #{action}")
    return HALT
  end

  def heartbeat
    # check reminders every 9 seconds (heartbeat is called every 3 sec)
    @heartbeat_counter ||= 0
    @heartbeat_counter += 1
    return unless (@heartbeat_counter % 3) == 1
    due_reminders.each do |reminder|
      bot.say("#{reminder.person}, I'm reminding you to #{reminder.action}")
      reminder.destroy!
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['remind (me|<person>) [in] <time string> to <message>', "set up a reminder"],
     ['remind (me|<person>) to <message> (in|on|at|next|this) <time string>', "set up a reminder"],
     ["[list|show] [person]['s] reminders", "display current reminders for yourself or person"],
     ["delete reminder <n>", "delete your reminder #n"],
    ]
  end
    
  private

  def due_reminders
    Reminder.all(:reminder_time.lte => Time.now)
  end
  
  def list_reminders(current_person, request_person)
    case request_person.downcase
    when 'my', 'me'
      request_person = current_person
    else
      request_person.gsub!(/'s$/i,'')
    end
    request_person.capitalize!
    
    case request_person
    when /everyone/i, /all/i      
      if (reminders = Reminder.all).any?
        bot.say("Here are all the reminders I have:")
        reminders.each do |reminder|
          bot.say("#{reminder.id} - [#{reminder.reminder_time}] - #{reminder.person} - #{reminder.action}")
        end
      end
      return
    else
      reminders = Reminder.all(:conditions => {:person => request_person}, :order => [:reminder_time])
      if reminders.any?
        if request_person == current_person
          bot.say("Here are the reminders I have for you, #{current_person}:")
        else
          bot.say("Here are the reminders for #{request_person}:")
        end
        reminders.each do |reminder|
          bot.say("#{reminder.id} - [#{reminder.reminder_time}] - #{reminder.action}")
        end
        return
      end
    end
    bot.say("I couldn't find any reminders for #{request_person}")
  end 
  
  def delete_reminder(current_person, id)
    reminder = Reminder.get(id)
    if reminder.person == current_person
      reminder.destroy
      bot.say("Ok, I've deleted reminder ##{id}.")
    else
      bot.say("Sorry, #{current_person}, but I couldn't find a reminder with that id that belongs to you.")
    end
  end    
end
