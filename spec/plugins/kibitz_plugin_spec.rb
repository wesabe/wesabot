require File.dirname(__FILE__) + '/../spec_helper'

describe KibitzPlugin do
  before do
    @plugin = KibitzPlugin.new
  end

  describe "when not addressing wes" do
    it "does not say anything" do
      saying("should we deploy?").
        should_not make_wes_say_anything
    end
  end

  describe "when addressing wes" do
    it "responds with the name of the sender when the message has no command" do
      saying("wes?").
        should make_wes_say("John")
    end

    it "says whatever the sender tells wes to when using the 'say' command" do
      saying("wes, say Hi There").
        should make_wes_say("Hi There")
    end

    it "responds with the same greeting the sender uses" do
      saying("hey wes").
        should make_wes_say("hey John")
    end

    it "responds with the same goodbye the sender uses" do
      saying("bye, wes").
        should make_wes_say("bye John")
    end

    it "responds politely to praise" do
      saying("yay! you rock, wes").
        should make_wes_say("Thanks, John, you're pretty cool yourself.")
    end

    it "says yes when the sender asks if wes is there" do
      asking("wes, yt?").
        should make_wes_say("Yup")
    end

    it "says hi informally when told to wake up" do
      asking("you awake wes?").
        should make_wes_say("Yo.")
    end

    it "responds politely to thanks" do
      asking("thanks, wes!").
        should make_wes_say("No problem.")
    end
  end
end
