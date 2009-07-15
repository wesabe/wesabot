require File.dirname(__FILE__) + '/../campfire/polling_bot'
require 'spec'

class FakeBot < Campfire::PollingBot
  def initialize
    self.name = 'Wes'
  end

  def say(message)
    transcript << [:say, message]
  end

  def paste(message)
    transcript << [:paste, message]
  end

  def say_random(messages)
    transcript << [:say, messages.first]
  end

  def transcript
    @transcript ||= []
  end
end

Spec::Runner.configure do |s|
  def load_plugins
    Campfire::PollingBot::Plugin.load_all(self)
  end

  def saying(what)
    bot = FakeBot.new
    @plugin.class.bot = bot
    message = Campfire::TextMessage.new(
      :body => what,
      :person => "John Tester"
    )
    @plugin.process(message) if @plugin.accepts?(message)
    return bot.transcript
  end

  alias :asking :saying

  def make_wes_say(what)
    MakeWesSend.new.and_say(what)
  end

  def make_wes_paste(what)
    MakeWesSend.new.and_paste(what)
  end

  def make_wes_say_something
    MakeWesSaySomething.new
  end

  alias :make_wes_say_anything :make_wes_say_something

  module MessagePrinter
    def print_messages(messages)
      messages.map {|e| "  #{e.first} #{e.last.inspect}"}.join("\n")
    end
  end

  class MakeWesSend
    include MessagePrinter

    def matches?(actual)
      @actual = actual

      if actual.size != expected.size
        @failure = [:size, actual.size, expected.size]
        return false
      end

      actual.zip(expected).each do |a, e|
        if a.first != e.first
          @failure = [:type, a, e]
          return false
        end

        case e.last
        when Regexp
          if a.last !~ e.last
            @failure = [:match, a, e]
            return false
          end
        else
          if e.last != a.last
            @failure = [:equal, a, e]
            return false
          end
        end
      end

      return true
    end

    def failure_message
      failure_type, actual, expected = *@failure

      case failure_type
      when :size
        "expected #{expected} message(s):\n\n" +
          print_messages(@expected) +
        "\n\ngot #{actual} message(s):\n\n" +
          print_messages(@actual)
      when :type
        "expected Wes to #{expected.first} #{expected.last.inspect}, " +
        "but got #{actual.first} #{actual.last.inspect}"
      when :match
        "expected Wes to #{expected.first} something matching #{expected.last.inspect}, " +
        "but got #{actual.last.inspect}"
      when :equal
        "expected Wes to #{expected.first} #{expected.last.inspect}, " +
        "but got #{actual.last.inspect}"
      else
        @failure.inspect
      end
    end

    def negative_failure_message
      "expected not to get the following message(s), but did:\n\n" +
        print_messages(@expected)
    end

    def and(expected)
      expect nil, expected
    end

    def and_say(expected)
      expect :say, expected
    end

    def and_paste(expected)
      expect :paste, expected
    end

    private

    def expect(type, message)
      type ||= @last_type
      expected << [type, message]
      @last_type = type
      return self
    end

    def expected
      @expected ||= []
    end
  end

  class MakeWesSaySomething
    include MessagePrinter

    def matches?(actual)
      actual.any?
    end

    def failure_message
      "expected Wes to say something, but he didn't"
    end

    def negative_failure_message
      "expected Wes not to say anything, but he did:\n\n" +
        print_messages(@expected)
    end
  end
end

load_plugins
