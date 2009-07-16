# Plugin to allow Wes to update and reload himself
class ReloadPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true

  def process(message)
    case message.command
    when /^reload/i
      bot.say("Updating and restarting...")
      system("git pull origin master")
      exec $0
      return HALT
    end
  end

  # return array of available commands and descriptions
  def help
    [['reload', "update and reload Wes"]]
  end
end
