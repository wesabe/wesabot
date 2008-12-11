# used by HistoryPlugin, among others
class Message
  include DataMapper::Resource
  property :id,           Serial
  property :room,         Integer, :nullable => false, :index => true
  property :message_id,   Integer, :nullable => false 
  property :message_type, String, :length => 20, :nullable => false, :index => true
  property :person,       String, :index => true
  property :link,         Text, :lazy => false
  property :body,         Text, :lazy => false
  property :timestamp,    Integer, :nullable => false, :index => true
end