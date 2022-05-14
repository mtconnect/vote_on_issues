class VoteOnIssuesController < ApplicationController
  # respond_to :html, :js
  unloadable

  before_action :find_project_by_issue, :authorize, :only => [ :cast_vote, :show_voters, :reset_votes ]

  def find_project_by_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  end
  
  def index
    @project = Project.find(params[:project_id])
    @votes = VoteOnIssue.all
  end

  def cast_vote
    @vote_value = 0;
    if 'vup' == params[:vote_value]
      @vote_value = 1
    elsif 'vdn' == params[:vote_value]
      @vote_value = -1
    end

    old_vote_value = nil
    begin
      @vote = VoteOnIssue.find_by!("issue_id = ? And user_id = ?", params[:issue_id], User.current.id)
      old_vote_value = @vote.vote_value
      if 0 != @vote_value
        @vote.vote_value = @vote_value
        @vote.save
      else
        @vote.destroy
      end
    rescue ActiveRecord::RecordNotFound
      if 0 != @vote_value
        @vote = VoteOnIssue.new
        @vote.user_id  = User.current.id
        @vote.issue_id = params[:issue_id]
        @vote.vote_value = @vote_value
        @vote.save
      end
    end
    
    @up_vote_count = VoteOnIssue.up_vote_count_for_issue(params[:issue_id])
    @down_vote_count = VoteOnIssue.down_vote_count_for_issue(params[:issue_id])
    @issue = Issue.find(params[:issue_id])
    @issue.init_journal(User.current)

    unless Setting.plugin_vote_on_issues['send_notifications'] == 'on'
      # Spam reduction
      notify_journal = @issue.current_journal.notify?
      @issue.current_journal.notify = false
      notify_issue = @issue.notify?
      @issue.notify = false
    end
    
    @issue.current_journal.details << JournalDetail.new(:property => 'attr',
                                                        :prop_key => 'vote',
                                                        :old_value => vote_value_text(old_vote_value),
                                                        :value => vote_value_text(@vote_value))
    
    @issue.save
    
    unless Setting.plugin_vote_on_issues['send_notifications'] == 'on'
      @issue.current_journal.notify = notify_journal
      @issue.notify = notify_issue
    end

    # Auto loads /app/views/vote_on_issues/cast_vote.js.erb
  end
  
  def show_voters
    @issue = Issue.find(params[:issue_id])
    @up_votes = VoteOnIssue.list_of_up_voters_for_issue(params[:issue_id])
    @down_votes = VoteOnIssue.list_of_down_voters_for_issue(params[:issue_id])
    # Auto loads /app/views/vote_on_issues/show_voters.js.erb
  end

  def download_votes
    fid = CustomField.all.where(name: 'Company').first.id
    @votes = VoteOnIssue.all.where(issue_id: params[:issue_id]).map do |vote|
      user = vote.user
      company = user.custom_value_for(fid).value
      [user.firstname, user.lastname, user.email_address.address, %{"#{company}"}, vote.vote_value]
    end.sort_by { |r| r[3].downcase }.map do |r|
      r.join(',')
    end.join("\n")

    render content_type: 'text/plain', layout: false
  end

  def reset_votes
    votes = VoteOnIssue.where(issue_id: params[:issue_id])
    begin
      votes.each { |vote| vote.destroy }
    rescue ActiveRecord::RecordNotFound
      # Cannot delete record
      Rails.logger.error "Cannot delete vote #{vote}: #{$!}"
    end

    @up_vote_count = 0
    @down_vote_count = 0
    @vote_value = 0
    
    @issue = Issue.find(params[:issue_id])
    @issue.init_journal(User.current)
    @issue.current_journal.details << JournalDetail.new(:property => 'attr',
                                                        :prop_key => 'all_votes',
                                                        :value => 'cleared')
    @issue.save
  end

  def vote_value_text(v)
    case v
    when nil
      nil
      
    when 0
      'withdrawn'
      
    when 1
      'up'
      
    when -1
      'down'
    end
  end
end
