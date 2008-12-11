# used by SMSPlugin
class SMSSetting
  include DataMapper::Resource
  property :id,            Serial
  property :person,        String, :index => true
  property :address,       String
end