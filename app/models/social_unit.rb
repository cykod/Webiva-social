


class SocialUnit < DomainModel

  belongs_to :parent, :class_name => 'SocialUnit', :foreign_key => 'parent_id'
  belongs_to :social_location
  
  has_many :children, :class_name => 'SocialUnit', :foreign_key => 'parent_id',:dependent => :nullify
  
  has_many :social_unit_members, :dependent => :destroy
  
  has_many :social_friends, :include => :end_user
  has_many :friends, :through => :social_friends,:class_name => 'EndUser',:order => 'last_name,first_name', :source => :friend_user
  
  has_many :end_users, :class_name => 'EndUser', :through => :members, :source => :end_user
  has_many :members, :class_name => 'SocialUnitMember'
  has_many :child_members, :class_name => 'SocialUnitMember', :foreign_key => 'social_unit_parent_id'
  has_many :child_end_users, :class_name => 'EndUser', :through => :child_members, :source => :end_user

  belongs_to :image_file, :class_name => 'DomainFile'
  
  belongs_to :social_unit_type

 

  validates_presence_of :name
#  validates_uniqueness_of :name, :scope => [ :social_location_id, :social_unit_type_id ], :message => 'has already been taken'


  def users(sub_group=nil)
   if !sub_group
    if self.social_unit_type.child_message?
      self.end_users + self.child_end_users
    else
      self.end_users
    end
   else
    self.members.find(:all,:conditions => ['status=?',sub_group]).map(&:end_user).compact
   end 
  end
  
  def image
    if self.image_file
      self.image_file
    else
      self.social_unit_type.missing_image
    end    
  end
  
  def class_name
    self.social_unit_type.name
  end
  
  
  def sub_groups
    if self.social_unit_type.sub_groups.to_s.strip.blank?
      [ nil ]
    else
      self.social_unit_type.sub_groups.to_s.strip.split(",").map { |elm| elm=elm.strip; elm.blank? ? nil : elm }.compact
    end
  end
  
  def add_member(usr,status='active',role='member')
    member = self.social_unit_members.find_by_end_user_id(usr.id,:lock => true)
    if !member
      member = self.social_unit_members.create(:end_user => usr,:role => role, :status => status)
      member.create_friends! if self.social_unit_type && self.social_unit_type.auto_friend?
      if self.social_unit_type.access_token
        usr.add_token!(self.social_unit_type.access_token,:target => self)
      end
      return member
    else
      member.update_attributes(:role => role ? role : member.role, :status => status ? status : member.status )
      return nil
    end
  end
  
  def after_update
    self.members.find(:all,:lock => true).each { |mem| mem.save }
  end
  
  def remove_member(usr)
    member = self.social_unit_members.find_by_end_user_id(usr.id)
    if member
      member.destroy
      true
    else
      false
    end
  end
  
  def user_friends(user,options={})
    self.friends.find(:all,options.merge(:conditions => ['social_friends.end_user_id=?',user.id]))  
  end
  
  def user_friends_count(user,options={})
    self.friends.count(:all,options.merge(:conditions => ['social_friends.end_user_id=?',user.id]))
  end  
  
  def administrators
    self.members.find(:all,:conditions => 'role = "admin"').collect { |usr| usr.end_user }.compact
  end
  
  def is_admin?(usr)
    return true if usr.is_a?(EndUser) && usr.has_role?('social_ghost')
    self.members.find_by_end_user_id_and_role(usr.is_a?(EndUser) ? usr.id : usr,'admin') ? true : false
  end

  def is_member?(usr)
    return true if usr.is_a?(EndUser) && usr.has_role?('social_ghost')
    self.members.find_by_end_user_id(usr.is_a?(EndUser) ? usr.id : usr) ? true : false
  end
  
  def is_child_member?(usr)
    return true if usr.is_a?(EndUser) && usr.has_role?('social_ghost')
    self.child_members.find_by_end_user_id(usr.is_a?(EndUser) ? usr.id : usr) ? true : false
  end
  
  def add_events_permission(usr)
    if self.social_unit_type.member_create_events?
      is_member?(usr)
    else
      is_admin?(usr)
    end
      
  end
  
  def gallery_can_upload(usr)
    is_member?(usr)
  end

  def gallery_can_edit(usr)
    is_admin?(usr)
  end

  def share_variables
    {}
  end
  
  def share_notification(atr)
     invite = SocialInvite.find_by_social_unit_id_and_email(self.id,atr['to_email']) || 
        SocialInvite.create(:social_unit_id => self.id,:end_user_id => atr['end_user_id'],:email => atr['to_email'],:admin_invite => atr['share_level'] == 'high')
        
     if !invite.admin_invite? && atr['share_level'] == 'high'
      invite.update_attribute(:admin_invite,true)
     end
  end

  # Helper method for token validation
  def token_valid?
    self.approved? && (self.approved_until.blank? || self.approved_until > Time.now)
  end
  

  
  def add_member_with_notification(usr,status='active',role='member')
    if(usr)
      member = self.add_member(usr,status,role)
      
      if member
        response = MessageTemplate.create_message('member_accepted',nil,{ :group_name => self.name })
        response.send_notification(usr) if response
      end
    end
  end
  
end


