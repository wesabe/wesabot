# Plugin to make Wes chatty (or annoying)
class KibitzPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  priority -1

  def process(message)
    person = message.person
    case message.command
    when /^\s*$/
      bot.say(person)
    when /say\s+(.*)/
      bot.say($1)
    when /^(hey|hi|hello|sup|howdy)/i
      bot.say("#{$1} #{person}")
    when /(^later|(?:good\s*)?bye)/i
      bot.say("#{$1} #{person}")
    when /you rock/i, /awesome/i, /cool/i
      sayings = ["Thanks, #{person}, you're pretty cool yourself.",
                 "I try.",
                 "Aw, shucks. Thanks, #{person}."]
      bot.say_random(sayings)
    when /(^|you|still)\s*there/i, /\byt\b/i
      bot.say_random(%w{Yup y})
    when /(wake up|you awake)/i
      bot.say("Yo.")
    when /zod/i
      sayings = ["Zod's a wanker.",
                 "I'd tell you about Zod, but you wouldn't listen. No one ever does.",
                 "somebody send Zod back to the Phantom Zone",
                 "Zod and I were friends, once. It all ended one awful night in El Paso over a bottle of shitty scotch and a ten-dollar whore. Christ, those were the days."]
      bot.say_random(sayings)
    when /thanks|thank you/i
      sayings = ["No problem.", "np", "any time", "that's what I'm here for", "You're welcome."]
      bot.say_random(sayings)
    else
      sayings = ["I have no idea what you're talking about, #{person}.",
                 "eh?",
                 "oh, interesting",
                 "say more, #{person}",
                 "#{person}, you do realize that you're talking to a bot with a very limited vocabulary, don't you?",
                 "Whatever, #{person}.",
                 "Marc, tell #{person} to leave me alone.",
                 "Not now, #{person}.",
                 "brb crying",
                 "How do you feel when someone says '#{message.command}' to you, #{person}?"]

      bot.say_random(sayings)
    end
  end
end
