

class SocialGroupRequest < DomainModel


  def self.register_request(user,group)
      self.find_by_end_user_id_and_social_unit_id(user.id,group.id) || self.create(:end_user_id => user.id, :social_unit_id => group.id)
  end
  
  def self.requested?(user,group)
   self.find_by_end_user_id_and_social_unit_id(user.id,group.id) ? true : false  
  end
end
