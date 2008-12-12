# Plugin to send SMS (well, email) messages
require 'net/smtp'
class SMSPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /(?:set)?\s+my\s+sms\s+address\s*(?:is|to|:)\s*(.+)/i
      address = $1
      if address =~ /"mailto:(.*?)"/
        address = $1
      end
      update_sms_address(message.person, address)
      bot.say("OK, #{message.person}, I've set your SMS address to #{address}")
      return HALT
    when /(?:set)?\s+(\w+?)'s\s+sms\s+address\s*(?:is|to|:)\s*(.+)/i
      person = $1
      address = $2
      if address =~ /"mailto:(.*?)"/
        address = $1
      end
      update_sms_address(person, address)
      bot.say("OK, #{message.person}, I've set #{$1}'s SMS address to #{$2}")
      return HALT     
    when /list sms addresses/i
      if (settings = SMSSetting.all(:order => [:person])).any?
        bot.say("Here are the SMS addresses I have:")
        settings.each { |setting| bot.say("  #{setting.person} - #{setting.address}") }
      else
        bot.say("Sorry, I don't have any SMS addresses yet.")
      end
      return HALT
    when /(?:sms|text|txt)\s+([^\s:]+):?\s*(.*)/i
      if address = send_sms(message.person, $1, $2)
        bot.say("Sent an SMS to #{$1} at #{address}")
      end
      return HALT
    end
  end
  
  # return array of available commands and descriptions
  def help
    [['set my sms address to: <address>', "set your sms address"],
     ["set <person>'s sms address to", "set someone else's sms address"],
     ['(sms|text|txt) <person>: <message>', "send an sms message"],
     ["list sms addresses", "list all sms addresses"]
    ]
  end
  
  private
  
  def update_sms_address(person, address)
    person.downcase!
    if setting = find_sms_setting(person)
      setting.update_attributes(:address => address)
    else
      SMSSetting.create(:person => person, :address => address)
    end
    return address
  end
  
  def send_sms(sender, recipient, message)
    if setting = find_sms_setting(recipient)
      send_email(sender, setting.address, message)
      return setting.address
    else
      bot.say("Sorry, I don't have an SMS address for #{recipient}.")
      return nil
    end
  end
  
  def find_sms_setting(person)
    SMSSetting.first(:person => person.downcase)
  end  
  
  def send_email(from, to, message)
    from += "@wesabe.com"
    msg = "From: #{from}\nTo: #{to}\n\n#{message}"
    begin
      Net::SMTP.start('localhost', 25, 'wesabe.com') { |smtp| smtp.send_message(msg, from, to) }
      return true
    rescue Exception => e
      bot.say("Hmm...couldn't send mail. Here's what happened when I tried:")
      bot.paste(e.message)
      return false
    end
  end
end
