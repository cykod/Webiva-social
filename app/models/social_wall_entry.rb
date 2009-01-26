

class SocialWallEntry < DomainModel


  validates_presence_of :message 
  
  belongs_to :target, :polymorphic => true
  belongs_to :end_user
  
end
