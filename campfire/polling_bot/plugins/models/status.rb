# used by StatusPlugin
class Status
  include DataMapper::Resource
  property :id,         Serial
  property :person,     String, :index => true
  property :value,      String
end
