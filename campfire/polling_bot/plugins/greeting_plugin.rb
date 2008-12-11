# Plugin to greet people when they enter, provide a catch-up url, and notify them of any "future" messages
# requires the HistoryPlugin
class GreetingPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  accepts :enter_message
  
  def process(message)
    wants_greeting = wants_greeting?(message.person_full_name)
    if message.kind_of?(Campfire::EnterMessage) && wants_greeting
      msg = "Hey #{message.person.downcase}."
      if link = catch_up_link(message.person_full_name)
        msg += " Catch up: #{link}"
      end 
      bot.say(msg)
      future_messages(message.person_full_name, message.person).each do |future_message|
        bot.say(future_message)
      end
    elsif message.kind_of?(Campfire::TextMessage)
      case message.command
      when /(disable|turn off) greetings/i
        wants_greeting(message.person_full_name, false)
        bot.say("OK, I've disabled greetings for you, #{message.person}")
        return HALT
      when /(enable|turn on) greetings/i
        wants_greeting(message.person_full_name, true)
        bot.say("OK, I've enabled greetings for you, #{message.person}")
        return HALT
      when /toggle greetings/i
        old_setting = wants_greeting?(message.person_full_name)
        wants_greeting(message.person_full_name, !old_setting)
        bot.say("OK, I've #{old_setting ? 'disabled' : 'enabled'} greetings for you, #{message.person}")
        return HALT
      when /catch me up|ketchup/i
        if link = catch_up_link(message.person_full_name)
          bot.say("Here you go, #{message.person}: #{link}")
        else
          bot.say("Hmm...couldn't find when you last logged out, #{message.person}")
        end
        return HALT
      end
    end
  end
  # return array of available commands and descriptions
  def help
    [['(disable|turn off) greetings', "don't say hi when you log in (you grump)"],
     ['(eanable|turn on) greetings', "say hi when you log in"],
     ['toggle greetings', "disable greetings if enabled, enable if disabled. You know--toggle."],
     ['catch me up|ketchup', "gives you a link to the point in the transcript where you last logged out"]
    ]
  end
  
  private
  
  # return the message id of the user's last entry before leaving the room
  def last_message_id(person_full_name)
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

      if last_left && (Time.now.to_i - last_left.timestamp > 120)
        return last_left.message_id
      end
    end
  end
    
  # get link to when the user last left the room so they can catch up
  # only give the link if they've been gone for more than 2 minutes
  def catch_up_link(person_full_name)
    if message_id = last_message_id(person_full_name)
      return "#{bot.base_uri}/room/#{bot.room}/transcript/message/#{message_id}"
    end
  end
  
  # Tell the person who's just entered about what people were asking them to 
  # read about while they were gone.
  def future_messages(person_full_name, person)
    future_messages = []
    verbs = ["invoked", "called to", "cried out for", "made a sacrifice to", "let slip",
             "doorbell ditched", "whispered sweetly to", "walked over broken glass to get to",
             "prayed to the god of", "ran headlong at", "checked in a timebomb for",
             "interpolated some strings TWO TIMES for", "wished upon a", "was like, oh my god",
             "went all", "tested the concept of"]
    future_person    = Regexp.new("future #{person}", Regexp::IGNORECASE)
    future_everybody = Regexp.new("future everybody", Regexp::IGNORECASE)
    
    if message_id = last_message_id(person_full_name)
      candidates = Message.all(
        :message_id.gt => message_id,
        :person.not => ['Fogbugz','Subversion','GeneralZod','Capistrano','Wes'],
        :message_type => 'Text')
      candidates.each do |row|
        if row.body.match(future_person)
          verbed = verbs[rand(verbs.size)]
          future_messages << "#{row.person} #{verbed} future #{person} at: #{bot.base_uri}/room/#{bot.room}/transcript/message/#{row.message_id}"
        elsif row.body.match(future_everybody)
          verbed = verbs[rand(verbs.size)]
          future_messages << "#{row.person} #{verbed} future everybody: \"#{row.body}\""
        end
      end
    end
    return future_messages
  end
             
  def wants_greeting?(person)
    unless @wants_greeting
      @wants_greeting = {}
      GreetingSetting.all.each { |setting| @wants_greeting[setting.person] = setting.wants_greeting }
    end
    
    if @wants_greeting[person].nil?
      GreetingSetting.create(:person => person, :wants_greeting => true)
      @wants_greeting[person] = true
    end
    
    return @wants_greeting[person]      
  end
  
  def wants_greeting(person, wants_greeting)
    setting = GreetingSetting.first(:person => person)
    setting.update_attributes(:wants_greeting => wants_greeting)
    @wants_greeting[person] = wants_greeting
  end
end

