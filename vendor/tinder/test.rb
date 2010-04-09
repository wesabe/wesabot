require "rubygems"
$:.unshift "./lib"
require "tinder"
cf = Tinder::Campfire.new 'footle', :token => "c96695ef88aa59d9bdd37eea772ce8526139acdd"
puts "*** users: #{cf.users.inspect}"
r = cf.rooms.first
r.listen do |m|
  puts "*** message: #{m.inspect}"
  r.speak "Pong, #{m[:user][:name]}!" if m[:body] =~ /ping/i
end
