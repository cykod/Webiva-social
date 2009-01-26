

class SocialBlock < DomainModel


  def self.blocked?(blocked_user,blocking_user)
    SocialBlock.find_by_blocked_user_id_and_end_user_id(blocked_user,blocking_user)
  end
end
