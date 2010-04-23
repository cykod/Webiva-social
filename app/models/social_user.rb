

class SocialUser < DomainModel
  
  belongs_to :end_user
  belongs_to :social_location

  def social_units(social_unit_type_id = nil)
    unless @social_units
      @social_units = SocialUnitMember.find(:all,:conditions => ['end_user_id=?',self.end_user_id],:include => :social_unit).map { |c| c.social_unit }
      @social_unit_types = @social_units.group_by(&:social_unit_type_id)
    end
    return @social_unit_types[social_unit_type_id.to_i]||[] if social_unit_type_id
    return @social_units
  end

  def social_unit_ids
    @social_units_ids ||= SocialUnitMember.find(:all,:conditions => ['end_user_id=?',self.end_user_id]).map { |c| c.social_unit_id }

  end
  
  def group_count(social_unit_type_id = nil)
    SocialUnitMember.count(:all,:conditions => ['end_user_id=? AND social_unit_type_id=?',self.end_user_id,social_unit_type_id])
  end

  def self.user(usr)
    find_by_end_user_id(usr.id) || SocialUser.create(:end_user_id => usr.id, :role => 'member')
  end
  
  def target_list
    self.social_units + [ self.end_user ]
  end

  def content_list
    self.social_unit_ids.map { |suid| [ "SocialUnit",suid ] } + [[ "EndUser", self.end_user_id ]]
  end

  def full_content_list
    self.content_list + SocialFriend.friends_cache_content(self.end_user_id)
  end

  def nested_full_content_list
    groups = {}
    self.full_content_list.each { |elm| groups[elm[0]] ||= []; groups[elm[0]] << elm[1] }
    groups.to_a
  end

  def share_variables
    {}
  end
  
  def update_member_roles(role) 
    ## TO DO: Update 
   SocialUnitMember.find(:all,:conditions => ['end_user_id=? AND social_units.social_unit_type_id = 2 ',self.end_user_id],:include => :social_unit).each do |member|
     member.update_attribute(:status,role) if member.status != role
   end
  end
  
  def share_notification(atr)
    SocialInvite.find_by_end_user_id_and_email(self.end_user_id,atr['to_email']) || 
        SocialInvite.create(:end_user_id => self.end_user_id,:email => atr['to_email'])
  end
end
