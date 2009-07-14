# Plugin to get a list of commits that are on deck to be deployed
class DeployPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true

  def process(message)
    case message.command
    when /on deck(?: for ([^\s\?]+))?/
      project = ($1 || config['default_project']).downcase
      info = project_info(project)
      if info.nil?
        bot.say("Sorry #{message.person}, I don't know anything about #{project}.")
      else
        shortlog = project_shortlog(project, "#{deployed_revision(project)}..HEAD")

        if shortlog.nil?
          bot.say("Sorry #{message.person}, I couldn't get what's on deck for #{project}.")
        else
          bot.say("Here's what's on deck for #{project}:")
          bot.paste(shortlog)
        end
      end

      return HALT
    end
  end

  def help
    [["what's on deck?", "get shortlog of to-be-deployed changes for #{config['default_project']}"],
     ["what's on deck for <project>?", "get the shortlog of to-be-deployed changes for a specific project"]]
  end

  private

  def project_info(project)
    config["project"][project]
  end
  
  def project_shortlog(project, treeish)
    info = project_info(project)
    return nil if info.nil?
    result = %x{ cd #{repository_path(project)}; git shortlog #{treeish} }
    if $?.exitstatus.zero?
      return result
    else
      return "Nothing is on deck right now."
    end
  end

  def deployed_revision(project)
    info = project_info(project)
    return nil if info.nil?
    return bot.get_content(info["deployed_revision_url"])
  end

  def repository_path(project)
    File.join(config["repository_base_path"], "#{project}.git")
  end
end
