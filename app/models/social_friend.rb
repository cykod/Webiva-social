
class SocialFriend < DomainModel

  belongs_to :end_user
  belongs_to :friend_user, :class_name => 'EndUser', :foreign_key => 'friend_user_id'
  
  validates_uniqueness_of :end_user_id, :scope => :friend_user_id

    
  def self.add_automatic_friend(usr1,usr2,options = {})
    if(!is_friend?(usr1,usr2))
      opts = { :automatic => true }
      opts[:social_unit_id] = options[:social_unit_id] if options[:social_unit_id]
      obj1 = self.create(opts.merge({ :end_user => usr1,:friend_user => usr2 }))
      obj2 = self.create(opts.merge({ :end_user => usr2,:friend_user => usr1 }))
      
      self.clear_friends_cache(usr1.id)    
      self.clear_friends_cache(usr2.id)    
      obj1.id && obj2.id # if we created both friend return true, else false
    end
  end
  
  def self.add_friend(usr1,usr2,options = {})
    if(!is_friend?(usr1,usr2))
      opts = { :automatic => false }
      opts[:social_unit_id] = options[:social_unit_id] if options[:social_unit_id]
      obj1 = self.create(opts.merge({ :end_user => usr1,:friend_user => usr2 }))
      obj2 = self.create(opts.merge({ :end_user => usr2,:friend_user => usr1 }))
      
      self.clear_friends_cache(usr1.id)    
      self.clear_friends_cache(usr2.id)    
      obj1.id && obj2.id # if we created both friend return true, else false
    end
    
  end


  def self.is_friend?(usr_from,usr_to)
    return true if usr_from.has_role?('social_ghost')
  
    self.find(:first,:conditions => ['end_user_id = ? AND friend_user_id = ?',usr_from.id,usr_to.id])  
  end
  
  def self.has_invite?(usr_from,usr_to)
    MessageMessage.find(:first, 
      :conditions => [ 'message_messages.from_user_id = ? AND handled=0 AND notification_class = "/social/friend_notification" AND message_recipients.to_user_id=?', usr_from, usr_to.id ],:joins => :message_recipients )
  end


  def self.remove_friend(usr1,usr2)
    usr1 = usr1.id if usr1.is_a?(EndUser)
    usr2 = usr2.id if usr2.is_a?(EndUser)
    
    SocialFriend.destroy_all(['end_user_id=? AND friend_user_id=?',usr1,usr2])
    SocialFriend.destroy_all(['end_user_id=? AND friend_user_id=?',usr2,usr1])
    
    self.clear_friends_cache(usr1)
    self.clear_friends_cache(usr2)
    true
  end
  
  def self.friends_cache(user_id)

    if user_id.is_a?(SocialUser)
      susr = user_id
      user_id = susr.end_user_id
    else
      user_id = user_id.id if user_id.is_a?(EndUser)
      susr = SocialUser.user(user_id)
    end
    
    friends = susr.cache_fetch("SocialFriends")
    unless friends
      friends = SocialFriend.find(:all,:select => 'friend_user_id',:conditions => ['end_user_id = ?',user_id]).map(&:friend_user_id)
      susr.cache_put("SocialFriends",friends)
    end
    
    friends
  end

  def self.friends_cache_content_profiles(user_id)
    if user_id.is_a?(SocialUser)
      susr = user_id
      user_id = susr.end_user_id
    else
      user_id = user_id.id if user_id.is_a?(EndUser)
      susr = SocialUser.user(user_id)
    end

    cached_content = susr.cache_fetch("SocialFriendsProfiles")
    unless cached_content 
      friends = self.friends_cache(susr)
      user_profile_entries = UserProfileEntry.fetch_entries(friends).map(&:id)
      cached_content = [ friends, user_profile_entries ] 
    end
    susr.cache_put("SocialFriendsProfiles",cached_content)

    cached_content[0].map { |elm| [ "EndUser",elm ] } + cached_content[1].map { |elm| [ "UserProfileEntry",elm ] }
  end

  def self.friends_cache_content(user_id)
    friends = self.friends_cache(user_id).map { |fid| [ "EndUser", fid ] }
  end
  
  def self.clear_friends_cache(user_id)
    SocialUser.user(user_id).content_cache_expire
  end
  
end

