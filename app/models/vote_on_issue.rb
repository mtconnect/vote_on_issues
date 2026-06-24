class VoteOnIssue < ActiveRecord::Base
  # Every vote belongs to a user and an issue
  belongs_to :user
  belongs_to :issue
  
  def self.current_user_vote_for_issue(issue)
    vote = VoteOnIssue.find_by("issue_id = ? AND user_id = ?", issue.id, User.current.id)
    if vote
      @vote = vote
      vote.vote_value
    else
      0
    end
  end
  
  def self.up_vote_count_for_issue(issue_id)
    where("issue_id = ? AND vote_value > 0", issue_id).count
  end
  
  def self.down_vote_count_for_issue(issue_id)
    where("issue_id = ? AND vote_value < 0", issue_id).count
  end

  def self.list_of_up_voters_for_issue(issue_id)
    # this does load the users, but costly: One query for each user
      # where("issue_id = ? AND vote_value > 0", issue_id)
    # this does load the users, less costly: One query for all users
      # includes(:user).where("issue_id = ? AND vote_value > 0", issue_id)
      # where("issue_id = ? AND vote_value > 0", issue_id).includes(:user)
    # joins users successfully, but still execs one query for each user 
      # where("issue_id = ? AND vote_value > 0", issue_id).joins(:user)
    # This does what I want, but I'd love to find out how to do this in rails...
    find_by_sql( ["SELECT `vote_on_issues`.`vote_value` AS vote_value, concat(`users`.`firstname`, ' ', `users`.`lastname`) AS user_login FROM `vote_on_issues` LEFT JOIN `users` ON (`users`.`id` = `vote_on_issues`.`user_id`) WHERE (`issue_id` = ? AND `vote_value` > 0) ORDER BY user_login ASC", issue_id] )
  end
  
  def self.list_of_down_voters_for_issue(issue_id)
    # see list_of_up_voters_for_issue
    find_by_sql( ["SELECT `vote_on_issues`.`vote_value` AS vote_value, concat(`users`.`firstname`, ' ', `users`.`lastname`) AS user_login FROM `vote_on_issues` LEFT JOIN `users` ON (`users`.`id` = `vote_on_issues`.`user_id`) WHERE (`issue_id` = ? AND `vote_value` < 0) ORDER BY user_login ASC", issue_id] )
  end
  
end
