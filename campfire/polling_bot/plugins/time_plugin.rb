# Simple sample plugin to just give the current time
class TimePlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /time/i
      bot.say("#{message.person}, the time is #{Time.now}")
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [['time', "say the current time"]]
  end
end