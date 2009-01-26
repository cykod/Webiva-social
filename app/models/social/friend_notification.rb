
class Social::FriendNotification < Message::Notification

  handle_actions :add_friend,:refuse_friend,:block
  
  def add_friend
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    if usr && recipient.to_user
      SocialFriend.add_friend(usr,recipient.to_user)
      msg.update_message(:success,{ :name => usr.name })
      
      response = MessageTemplate.create_message('friend_accepted',recipient.to_user)
      response.send_notification(usr)
      
    end
  end
  
  def refuse_friend
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    if usr && recipient.to_user
      msg.update_message(:failure,{ :name => usr.name })
      
      response = MessageTemplate.create_message('friend_rejected', recipient.to_user)
      response.send_notification(usr)
    end
  end
  
  def block
    usr = EndUser.find_by_id(msg.data[:from_user_id])
    if usr && recipient.to_user
      msg.update_message(:other,{ :name => usr.name })
      
      SocialBlock.find_by_end_user_id_and_blocked_user_id(recipient.to_user.id,usr.id) ||
          SocialBlock.create(:end_user_id => recipient.to_user.id,:blocked_user_id => usr.id)
      
      response = MessageTemplate.create_message('friend_blocked',recipient.to_user)
      response.send_notification(usr)
    end

  end
  

end
