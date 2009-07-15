# PollingBot - a bot that polls the room for messages
require 'campfire/bot'

class Campfire
  class PollingBot < Bot
    require 'campfire/polling_bot/plugin'
    attr_accessor :plugins
    POLL_INTERVAL = 3 # seconds

    def initialize(params = {})
      # load plugin queue, sorting by priority
      self.plugins = Plugin.load_all(self)
      super
    end

    def run
      trap('INT') { client.leave_room; exit } # if we're interrupted, leave the room
      heartbeat_counter = 0
      last_id = nil
      while true
        # send heartbeats to any plugins that want them
        plugins.each {|p| p.heartbeat if p.respond_to?(:heartbeat)}
        heartbeat_counter += 1
        client.keep_alive if heartbeat_counter % (60/POLL_INTERVAL) == 0 # do a keep-alive request every minute
        messages = client.poll(last_id)
        if messages.any?
          messages.each {|m| process(m)}
          last_id = messages[-1].message_id
        end
        begin
          sleep POLL_INTERVAL
        rescue Errno::EINVAL # not sure why, but sleep occasionally throws this
          puts "sleep barfed!"
        end
      end
    rescue Exception => e # leave the room if we crash
      unless e.kind_of?(SystemExit)
        # get the full stack trace...none of this shortened bullshit
        puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        client.leave_room
        exit 1
      end
    end

    def process(message)
      puts "processing #{message} #{('(' + message.person + ' - ' + message.body + ')') if message.respond_to?(:body)}" if debug
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
