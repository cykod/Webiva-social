

class SocialUnitMember < DomainModel

  belongs_to :end_user
  belongs_to :social_unit
  
  validates_presence_of :end_user, :social_unit
  
  has_options :role, [['Member','member'],['Administrator','admin']]
  
  def before_save
    if self.social_unit
      self.social_unit_type_id = self.social_unit.social_unit_type_id
      self.social_unit_parent_id = self.social_unit.parent_id
    end
  end

  def self.user_units(user)
    members = self.find(:all,:conditions => ['end_user_id = ?',user],:include => :social_unit)
    members.map { |member| member.social_unit }
  end

  def self.member_groups(user_id)
    members = self.find(:all,:conditions => ['end_user_id = ?',user_id],:include => :social_unit)
  end
  
  def create_friends!
    self.social_unit.social_unit_members.find(:all).each do |member|
      SocialFriend.add_automatic_friend(self.end_user,member.end_user,:social_unit_id => self.social_unit_id) if member.end_user_id != self.end_user.id
    end
  end

end
