
class Social::MemberInvite < Message::Notification

  handle_actions :accept_invitation, :reject_invitation
  
  def accept_invitation
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    group = SocialUnit.find_by_id(msg.data[:group_id])
    if group && recipient.to_user
      msg.update_message(:success,{ :group_name => group.name, :user => recipient.to_user })
      
      group.add_member(recipient.to_user)
      
    end
  end
  
  def reject_invitation
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    group = SocialUnit.find_by_id(msg.data[:group_id])
    if group && recipient.to_user
      msg.update_message(:failure,{ :group_name => group.name, :user => recipient.to_user })
    end
  end
  

end
