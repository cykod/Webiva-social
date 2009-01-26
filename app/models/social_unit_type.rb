
class SocialUnitType < DomainModel

  has_many :social_units
  
  belongs_to :parent_type,:class_name => 'SocialUnitType',:foreign_key => 'parent_type_id'


  belongs_to :content_model
  
  belongs_to :missing_image, :class_name => 'DomainFile'
    
  def parent_name
    if self.has_parents? && self.parent_type
      self.parent_type.name
    else
      "Invalid Parent"
    end
  end
  
  def categories
    self.category_options.split(",").map { |elm| elm.strip }
  end


end
