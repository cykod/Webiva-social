
class Social::MemberNotification < Message::Notification

  handle_actions :add_member,:cancel_member
  
  def add_member
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    group = SocialUnit.find_by_id(msg.data[:group_id])
    if usr && group
      msg.update_message(:success,{ :group_name => group.name, :user => usr })
      
      group.add_member_with_notification(usr)
      
    end
  end
  
  def cancel_member
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    group = SocialUnit.find_by_id(msg.data[:group_id])
    if usr && recipient.to_user
      msg.update_message(:failure,{ :name => usr.name })
      
      response = MessageTemplate.create_message('member_refused',nil,{ :group_name => group.name, :user => usr })
      response.send_notification(usr)
    end
  end
  

end
