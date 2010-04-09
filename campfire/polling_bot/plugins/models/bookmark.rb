# used by BookmarksPlugin
class Bookmark
  include DataMapper::Resource
  property :id,           Serial
  property :room,         Integer, :required => true, :index => true
  property :message_id,   Integer, :required => true 
  property :person,       String, :index => true
  property :name,         String, :index => true
  property :timestamp,    Time, :required => true, :index => true

  # return link to bookmark
  def link
    "/room/#{self.room}/transcript/message/#{self.message_id}"
  end
end