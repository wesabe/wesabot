# Plugin to get a list of commits that are on deck to be deployed
class DeployPlugin < Campfire::PollingBot::Plugin
  accepts :text_message, :addressed_to_me => true

  def process(message)
    case message.command
    when /on deck(?: for ([^\s\?]+))?/
      project = $1

      if not projects.any?
        bot.say("Sorry #{message.person}, I don't know about any projects. Please configure the deploy plugin.")
        return HALT
      end

      project ||= default_project
      if project.nil?
        bot.say("Sorry #{message.person}, I don't have a default project. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end
      project.downcase!

      info = project_info(project)
      if info.nil?
        bot.say("Sorry #{message.person}, I don't know anything about #{project}. Here are the projects I do know about:")
        bot.paste(projects.keys.sort.join("\n"))
        return HALT
      end

      range = nil
      begin
        range = "#{deployed_revision(project)}..HEAD"
        shortlog = project_shortlog(project, range)
      rescue => e
        bot.say("Sorry #{message.person}, I couldn't get what's on deck for #{project}, got a #{e.class}:")
        bot.paste("#{e.message}\n\n#{e.backtrace.map{|l| "  #{l}\n"}}")
        return HALT
      end

      if shortlog.nil? || shortlog =~ /^\s*$/
        bot.say("There's nothing on deck for #{project} right now.")
        return HALT
      end

      bot.say("Here's what's on deck for #{project}:")
      bot.paste("$ git shortlog #{range}\n\n#{shortlog}")

      return HALT
    end
  end

  def help
    help_lines = [["what's on deck for <project>?", "get the shortlog of to-be-deployed changes for a specific project"]]
    help_lines << ["what's on deck?", "get shortlog of to-be-deployed changes for #{default_project}"] unless default_project.nil?
    return help_lines
  end

  def projects
    (config && config['project']) || {}
  end

  def default_project
    (config && config['default_project']) ||
      (projects.size == 1 ? projects.keys.first : nil)
  end

  private

  def project_info(project)
    projects[project]
  end

  def project_shortlog(project, treeish)
    info = project_info(project)
    return nil if info.nil?
    result = %x{ cd #{repository_path(project)}; git shortlog #{treeish} }
    if $?.exitstatus.zero?
      return result
    else
      raise "got non-zero exit status from git shortlog: #{$?.exitstatus}"
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
