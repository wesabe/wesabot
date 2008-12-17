class StatusPlugin < Campfire::PollingBot::Plugin
  accepts :text_message

  def process(message)
    case message.body
    when /(?:what's|what is|where's|where is)\s+(\w+)/i
      person = $1
      if person =~ /everyone/i
        show_statuses
      else
        status = Status.first(:person => person.downcase)
        if status.nil?
          # I don't know
          return unless message.addressed_to_me?
          bot.say("I don't know what #{person} is doing.")
        else
          bot.say("#{person} is #{status.value}")
        end
      end

      return HALT
    end

    return unless message.addressed_to_me?

    case message.command
    when /(?:set)?\s+my\s+status(?:\s+is|to|:)\s*(.+)/i
      status = strip_quotes($1)
      update_status(message.person, status)
      return HALT
    when /I'm\s+(.+)/i
      status = $1
      update_status(message.person, status)
      return HALT
    when /(?:show|list)\s+(\S+)?\s*status(?:es)?/i
      person = $1.replace(/'s$/i, '')
      if person =~ /(everyone|all)/i
        show_statuses
      else
        show_status_for(person)
      end
      return HALT
    when /(what's|what is)\s+(everyone\s+)?(up(\s+to)?|doing|going\s+on|happening)/i
      show_statuses
      return HALT
    end
  end

  def help
    [["set my status to: <status>", "set your status"],
     ["show <person>'s status", "show the status for <person>"],
     ["list all statuses", "show the statuses for everyone"],
     ["what's <person> up to?", "show the status for <person> -- works without addressing me"]]
  end

  def show_statuses
    statuses = Status.all(:order => [:person])
    if statuses.any?
      bot.say("Here's what everyone said they were doing:")
      statuses.each { |status| bot.say("  #{status.person} - #{status.value}") }
    else
      bot.say("Sorry, no one wants to share their activities with a lowly bot.")
    end
  end

  def show_status_for(person)
    person.downcase!
    status = Status.first(:person => person)
    if status
      bot.say("#{person} is #{status.value}")
    else
      bot.say("I don't know what #{person} is doing.")
    end
  end

  def update_status(person, value)
    person.downcase!
    if status = Status.first(:person => person)
      status.update_attributes(:value => value)
    else
      Status.create(:person => person, :value => value)
    end
    bot.say("Duly noted, #{person}.")
  end
end
