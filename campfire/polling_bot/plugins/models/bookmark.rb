# used by BookmarksPlugin
class Bookmark
  include DataMapper::Resource
  property :id,           Serial
  property :room,         Integer, :nullable => false, :index => true
  property :message_id,   Integer, :nullable => false 
  property :person,       String, :index => true
  property :name,         String, :index => true
  property :timestamp,    Time, :nullable => false, :index => true

  # return link to bookmark
  def link
    "/room/#{self.room}/transcript/message/#{self.message_id}"
  end
end