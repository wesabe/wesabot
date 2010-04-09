# PollingBot - a bot that polls the room for messages
require 'campfire/bot'
require 'campfire/message'

class Campfire
  class PollingBot < Bot
    require 'campfire/polling_bot/plugin'
    attr_accessor :plugins
    HEARTBEAT_INTERVAL = 3 # seconds

    def initialize(params = {})
      # load plugin queue, sorting by priority
      self.plugins = Plugin.load_all(self)
      super
    end

    # main event loop
    def run
      # if we're interrupted, leave the room
      trap('INT') { room.leave; exit }
      
      # set up a heartbeat thread for plugins that want them
      Thread.new do
        while true
          plugins.each {|p| p.heartbeat if p.respond_to?(:heartbeat)}
          sleep HEARTBEAT_INTERVAL
        end
      end
      
      room.listen do |message|
        klass = Campfire.const_get(message[:type])
        message = klass.new(message)
        process(message)
      end
      
    rescue Exception => e # leave the room if we crash
      unless e.kind_of?(SystemExit)
        # get the full stack trace...none of this shortened bullshit
        puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        room.leave
        exit 1
      end
    end

    def process(message)
      puts "processing #{message} (#{message.person} - #{message.body})" if debug
      plugins.each do |plugin|
        if plugin.accepts?(message)
          puts "sending to plugin #{plugin} (priority #{plugin.priority})" if debug
          if plugin.process(message) == Plugin::HALT
            puts "plugin chain halted" if debug
            break
          end
        end
      end
    end

    # determine if a message is addressed to the bot. if so, store the command in the message
    def addressed_to_me?(message)
      if m = message.body.match(/^\b#{name}[,:]\s*(.*)/i) || message.body.match(/^\s*(.*?)[,]?\b#{name}[.!?\s]*$/i)
        message.command = m[1]
      end
    end
  end
end
