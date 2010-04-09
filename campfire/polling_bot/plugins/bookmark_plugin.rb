# Plugin to allow saving of transcript bookmarks
class BookmarkPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true
  
  def process(message)
    case message.command
    when /^(?:add |create )?bookmark:?\s*(?:this as:?)?\s*("?)(.*?)\1$/i
      save_bookmark(message, $2)
      bot.say("Ok, saved bookmark: #{$2}")
      return HALT
    when /(?:list|show) (\S+) bookmarks/i, /(?:list|show) bookmarks for (\S+)/i
      list_bookmarks(message.person, $1)
      return HALT
    when /(list|show) bookmarks$/
      list_bookmarks(message.person, message.person)
      return HALT
    when /delete bookmark (?:#\s*)?(\d+)/
      delete_bookmark(message.person, $1.to_i)
      return HALT
      
    end
  end
  
  # return array of available commands and descriptions
  def help
    [["bookmark: <name>", "bookmark the current location"]]
  end
  
  private
  
  def save_bookmark(message, name)
    Bookmark.create(:person => message.person, 
                    :name => name, 
                    :room => bot.room.id,
                    :message_id => message.message_id, 
                    :timestamp => Time.now)
  end

  def list_bookmarks(current_person, request_person)
    case request_person.downcase
    when 'my', 'me'
      request_person = current_person
    else
      request_person.gsub!(/'s$/i,'')
    end
    request_person.capitalize!
    
    case request_person
    when /everyone/i, /all/i      
      if (bookmarks = Bookmark.all(:order => [:name])).any?
        bot.say("Here are all the bookmarks I have:")
        bookmarks.each do |bookmark|
          bot.say("#{bookmark.id} - #{bookmark.name} (#{bookmark_link(bookmark)}) by #{bookmark.person}")
        end
      end
      return
    else
      bookmarks = Bookmark.all(:conditions => {:person => request_person}, :order => [:name])
      if bookmarks.any?
        if request_person == current_person
          bot.say("Here are the bookmarks I have for you, #{current_person}:")
        else
          bot.say("Here are the bookmarks for #{request_person}:")
        end
        bookmarks.each do |bookmark|
          bot.say("#{bookmark.id} - #{bookmark.name} (#{bookmark_link(bookmark)})")
        end
        return
      end
    end
    bot.say("I couldn't find any bookmarks for #{request_person}")
  end
  
  def delete_bookmark(current_person, id)
    bookmark = Bookmark.get(id)
    if bookmark.person == current_person
      bookmark.destroy
      bot.say("Ok, I've deleted bookmark ##{id}.")
    else
      bot.say("Sorry, #{current_person}, but I couldn't find a bookmark with that id that belongs to you.")
    end
  end

  # return link to bookmark
  def bookmark_link(bookmark)
    bot.base_uri + bookmark.link
  end

end