# Campfire AbstractPollingBot Plugin base class
#
# To create a plugin, extend from this class, and just drop it into the plugins directory.
# See sample_plugin.rb for more information.
#
require 'dm-core'

class Campfire
  class PollingBot
    class Plugin
      attr_accessor :config

      def initialize
        # load the config file if we have one
        name = self.to_s.gsub(/([[:upper:]]+)([[:upper:]][[:lower:]])/,'\1_\2').
            gsub(/([[:lower:]\d])([[:upper:]])/,'\1_\2').
            tr("-", "_").
            downcase
        filepath = File.dirname(__FILE__) + "/plugins/config/#{name}.yml"
        if File.exists?(filepath)
          self.config = YAML.load_file(filepath)
        end
      end

      # keep track of subclasses
      def self.inherited(klass)
        super if defined? super
      ensure
        ( @subclasses ||= [] ).push(klass).uniq!
      end

      def self.subclasses
        @subclasses ||= []
        @subclasses.inject( [] ) do |list, subclass|
          list.push(subclass, *subclass.subclasses)
        end
      end

      # bot accessor
      def self.bot; @@bot end
      def bot; @bot || self.class.bot end
      attr_writer :bot

      HALT = 1 # returned by a command when command processing should halt (continues by default)

      def self.load_all(bot)
        @@bot = bot

        # load all models & plugins
        paths  = Dir.glob(File.dirname(__FILE__) + "/plugins/models/*.rb")
        paths += Dir.glob(File.dirname(__FILE__) + "/plugins/*.rb")
        paths.each do |path|
          begin
            path.match(/(.*?)\.rb$/) && (require $1)
          rescue Exception => ex
            $stderr.puts "!! Unable to load #{path}: #{ex.message}", *ex.backtrace
          end
        end

        # set up the database now that the plugins are loaded
        setup_database

        plugin_classes = self.subclasses.sort {|a,b| b.priority <=> a.priority }
        # initialize plugins
        plugins = plugin_classes.map { |p_class| p_class.new }
        return plugins
      end

      # set up the plugin database
      def self.setup_database
        DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/campfire/polling_bot/plugins/data/plugin.db")
        DataMapper.auto_upgrade!
      end

      # method to set or get the priority. Higher value == higher priority. Default is 0
      # command subclasses set their priority like so:
      #   class FooPlugin << Campfire::PollingBot::Plugin
      #     priority 10
      #   ...
      def self.priority(value = nil)
        if value
          @priority = value
        end
        return @priority || 0
      end

      # convenience method to get the priority of a plugin instance
      def priority
        self.class.priority
      end

      # called from Plugin objects to indicate what kinds of messages they accept
      # if the :addressed_to_me flag is true, it will only accept messages addressed
      # to the bot (e.g. "Wes, ____" or "______, Wes")
      # Examples:
      #   accepts :text_message, :addressed_to_me => true
      #   accepts :enter_message
      #   accepts :all
      def self.accepts(message_type, params = {})
        @accepts ||= {}
        if message_type == :all
          @accepts[:all] = params[:addressed_to_me] ? :addressed_to_me : :for_anyone
        else
          klass = Campfire.const_get(message_type.to_s.gsub(/(?:^|_)(\S)/) {$1.upcase})
          @accepts[klass] = params[:addressed_to_me] ? :addressed_to_me : :for_anyone
        end
      end

      # returns true if the plugin accepts the given message type
      def self.accepts?(message)
        if @accepts[:all]
          @accepts[:all] == :addressed_to_me ? bot.addressed_to_me?(message) : true
        elsif @accepts[message.class]
          @accepts[message.class] == :addressed_to_me ? bot.addressed_to_me?(message) : true
        end
      end

      # convenience method to call accepts on a plugin instance
      def accepts?(message)
        self.class.accepts?(message)
      end

      def to_s
        self.class.to_s
      end
    end
  end
end
