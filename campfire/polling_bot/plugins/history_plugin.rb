# records every message the bot receives
class HistoryPlugin < Campfire::PollingBot::Plugin
  accepts :all
  priority 100
  
  def process(message)
    @room_locked ||= false
    if message.kind_of?(Campfire::LockMessage)
      @room_locked = true
      return
    elsif message.kind_of?(Campfire::UnlockMessage)
      @room_locked = false
      return
    end
    
    save_message(message) unless @room_locked
  end
  
  private
  
  def save_message(message)
    Message.create(
      :room => bot.room,
      :message_id => message.message_id,
      :message_type => message.class.to_s.gsub(/Campfire::(.*?)Message$/, '\1'),
      :person => message.respond_to?(:person_full_name) ? message.person_full_name : nil,
      :link => message.respond_to?(:link) ? message.link : nil,
      :body => message.respond_to?(:body) ? message.body : nil,
      :timestamp => message.timestamp.to_i)
  end
end
