# used by GreetingPlugin
class GreetingSetting
  include DataMapper::Resource
  property :id,           Serial
  property :person,       String, :index => true
  property :wants_greeting, Boolean
end
