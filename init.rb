require 'redmine'

Redmine::Plugin.register :vote_on_issues do
  name 'Vote On Issues'
  description 'This plugin allows to up- and down-vote issues.'
  version '1.0.2'
  url 'https://github.com/ojde/redmine-vote_on_issues-plugin'
  author 'Ole Jungclaussen'
  author_url 'https://jungclaussen.com'

  requires_redmine :version_or_higher => '4.1.1'

  project_module :vote_on_issues do
    permission :cast_votes,     { vote_on_issues: [:cast_vote]      }, :require => :loggedin
    permission :view_votes,     { vote_on_issues: [:view_votes]     }, :require => :loggedin
    permission :show_voters,    { vote_on_issues: [:show_voters]    }, :require => :loggedin
    permission :reset_votes,    { vote_on_issues: [:reset_votes]    }, :require => :loggedin
    permission :download_votes, { vote_on_issues: [:download_votes] }, :require => :loggedin
  end

  settings :default => { 'send_notifications' => nil },
           :partial  => 'settings/vote_on_issues'
end

# Opt lib/ out of Zeitwerk autoloading — the files don't follow its naming
# conventions (e.g. hooks.rb defines VoteOnIssuesHooks::Hooks, not Hooks).
Rails.autoloaders.each { |loader| loader.ignore(File.join(__dir__, 'lib')) }

# Defer all class-level setup until after Rails has finished autoloading.
# IssueQuery, Query, Issue, and QueryColumn are guaranteed to exist by then.
Rails.application.config.to_prepare do
  require_dependency File.join(__dir__, 'lib', 'voi_query_column')
  require_dependency File.join(__dir__, 'lib', 'vote_on_issues', 'patches', 'query_patch')
  require_dependency File.join(__dir__, 'lib', 'vote_on_issues_hooks')

  issue_query = (IssueQuery rescue Query)
  issue_query.add_available_column(
    VoiQueryColumn.new(:sum_votes_up,
      :sortable => '(SELECT abs(sum(vote_value)) FROM vote_on_issues WHERE vote_value > 0 AND issue_id=issues.id)'))
  issue_query.add_available_column(
    VoiQueryColumn.new(:sum_votes_dn,
      :sortable => '(SELECT abs(sum(vote_value)) FROM vote_on_issues WHERE vote_value < 0 AND issue_id=issues.id)'))
  issue_query.add_available_column(
    VoiQueryColumn.new(:my_vote,
      :sortable => lambda { "(SELECT vote_value FROM vote_on_issues WHERE issue_id=issues.id and user_id=#{User.current.id})" }))

  Issue.include(VoteOnIssues::Patches::QueryPatch)
end

# Safe to define at load time — no autoloaded classes referenced.
class VoteOnIssuesListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :inline => <<-END
    <%= stylesheet_link_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
    <%= javascript_include_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
  END
end
