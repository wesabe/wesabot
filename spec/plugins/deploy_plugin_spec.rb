require File.dirname(__FILE__) + '/../spec_helper'

describe DeployPlugin do
  def use_example_config
    @plugin.config = {
      'project' => {
        'my_super_site' => {
          'deployed_revision_url' => 'http://www.example.com/REVISION'
        },

        'other' => {
          'deployed_revision_url' => 'http://www.other.com/REVISION'
        }}}
  end

  def use_no_config
    @plugin.config = nil
  end

  def use_blank_config
    @plugin.config = {'project' => {}}
  end

  before do
    @plugin = DeployPlugin.new
  end

  context "with no configuration" do
    before do
      use_no_config
    end

    it "has no default project" do
      @plugin.default_project.should be_nil
    end

    it "has an empty hash of projects" do
      @plugin.projects.should == {}
    end

    it "omits the short form of the 'on deck' command from the help" do
      @plugin.help.should have(1).item
    end
  end

  describe "the 'on deck' command" do
    context "with no projects" do
      before do
        use_blank_config
      end

      it "tells the sender that it doesn't know about any projects" do
        asking("wes, what's on deck?").
          should make_wes_say( %r{I don't know about any projects} )
      end
    end

    context "with projects" do
      before do
        use_example_config
        @plugin.stub!(:deployed_revision).and_return('abcde')
      end

      it "tells the sender when the project asked about does not exist" do
        asking("wes, what's on deck for foobar?").
          should make_wes_say( %r{I don't know anything about foobar} ).
                 and_paste("my_super_site\nother")
      end

      context "with no default project" do
        before do
          @project.stub!(:default_project).and_return(nil)
        end

        context "and more than one registered project" do
          it "lists available projects when the project is omitted" do
            asking("wes, what's on deck?").
              should make_wes_say( %r{I don't have a default project} ).
                     and_paste("my_super_site\nother")
          end
        end

        context "and only one registered project" do
          before do
            @plugin.projects.delete(@plugin.projects.keys.first) while @plugin.projects.size > 1
          end

          it "uses the only listed project as the default project" do
            @plugin.default_project.should == @plugin.projects.keys.first
          end
        end
      end

      context "with a default project" do
        before do
          @plugin.stub!(:default_project).and_return('my_super_site')
          @plugin.stub!(:project_shortlog).
                  and_return("John Tester (1):\n    Fix homepage links.\n")
        end

        it "uses the default project when the project is omitted" do
          asking("wes, what's on deck?").
            should make_wes_say( %r{Here's what's on deck for my_super_site} ).
                   and_paste(anything)
        end
      end

      context "when there is nothing on deck" do
        before do
          @plugin.stub!(:project_shortlog).
                  and_return('')
        end

        it "responds that nothing is on deck for the project" do
          asking("wes, what's on deck for my_super_site?").
            should make_wes_say("There's nothing on deck for my_super_site right now.")
        end
      end

      context "when there is something on deck" do
        before do
          @plugin.stub!(:project_shortlog).
                  and_return("John Tester (1):\n    Fix homepage links.\n\n")
        end

        it "responds with the shortlog for the project" do
          asking("wes, what's on deck for my_super_site?").
            should make_wes_say("Here's what's on deck for my_super_site:").
                    and_paste(<<-EOS)
$ git shortlog abcde..HEAD

John Tester (1):
    Fix homepage links.

EOS
        end
      end

      context "when getting the shortlog fails" do
        before do
          @plugin.stub!(:project_shortlog).
                  and_raise("testing")
        end

        it "reports the error to the user" do
          asking("wes, what's on deck for my_super_site?").
            should make_wes_say("Sorry John, I couldn't get what's on deck for my_super_site, got a RuntimeError:").
                  and_paste( %r{testing} )
        end
      end
    end
  end
end
