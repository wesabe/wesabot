# used by RemindMe plugin
class Reminder
  include DataMapper::Resource
  property :id,            Serial
  property :person,        String, :index => true
  property :action,        Text, :lazy => false
  property :reminder_time, Time, :required => true, :index => true
end