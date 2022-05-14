require 'redmine'
require_dependency 'hooks' 
require_dependency 'query_column'

# patch issue_query to allow columns for votes
issue_query = (IssueQuery rescue Query)
issue_query.add_available_column(VOI_QueryColumn.new(:sum_votes_up, :sortable => '(SELECT abs(sum(vote_value)) FROM vote_on_issues WHERE vote_value > 0 AND issue_id=issues.id )'))
issue_query.add_available_column(VOI_QueryColumn.new(:sum_votes_dn, :sortable => '(SELECT abs(sum(vote_value)) FROM vote_on_issues WHERE vote_value < 0 AND issue_id=issues.id )'))
issue_query.add_available_column(VOI_QueryColumn.new(:my_vote, :sortable => lambda { "(SELECT vote_value FROM vote_on_issues WHERE issue_id=issues.id and user_id=#{User.current.id})" } ))


Issue.send(:include, VoteOnIssues::Patches::QueryPatch)


Redmine::Plugin.register :vote_on_issues do
  name 'Vote On Issues'
  description 'This plugin allows to up- and down-vote issues.'
  version '1.0.2'
  url 'https://github.com/ojde/redmine-vote_on_issues-plugin'
  author 'Ole Jungclaussen'
  author_url 'https://jungclaussen.com'
  
  requires_redmine  :version_or_higher => '4.1.1'
  
  project_module :vote_on_issues do
    permission :cast_votes, { vote_on_issues: [:cast_vote] }, :require => :loggedin
    permission :view_votes, { vote_on_issues: [:view_votes] }, :require => :loggedin
    permission :show_voters, { vote_on_issues: [ :show_voters ] }, :require => :loggedin   
    permission :reset_votes, { vote_on_issues: [ :reset_votes ] }, :require => :loggedin   
    permission :download_votes, { vote_on_issues: [ :download_votes ] }, :require => :loggedin   
  end

  # permission for menu
  # permission :vote_on_issues, { :vote_on_issues => [:index] }, :public => true
  # menu :project_menu,
  #   :vote_on_issues, 
  #   { :controller => 'vote_on_issues', :action => 'index' },
  #   :caption => :menu_title,
  #   :after => :issues,
  #   :param => :project_id,
  #   :if =>  Proc.new {
  #     User.current.allowed_to?(:view_votes, nil, :global => true)
  #   }

  settings :default => {
     'send_notifications' => nil
  }, :partial => 'settings/vote_on_issues'
  
end

class VoteOnIssuesListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :inline =>  <<-END
      <%= stylesheet_link_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
      <%= javascript_include_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
    END
end
