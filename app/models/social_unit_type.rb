
class SocialUnitType < DomainModel

  has_many :social_units
  
  belongs_to :parent_type,:class_name => 'SocialUnitType',:foreign_key => 'parent_type_id'

  belongs_to :access_token

  belongs_to :content_model
  
  belongs_to :missing_image, :class_name => 'DomainFile'

  content_node_type :social_unit, "SocialUnit", :content_name => :name,:title_field => :name, :url_field => :url
    
  def parent_name
    if self.has_parents? && self.parent_type
      self.parent_type.name
    else
      "Invalid Parent"
    end
  end

  def content_type_name
    "Social Unit Type"
  end

  def content_admin_url(social_unit_id)
    { :controller => '/social/manage/units', :action => 'view', :path => social_unit_id } 
  end
  
  def categories
    self.category_options.split(",").map { |elm| elm.strip }
  end

  def before_validation
    if self.content_model
      if core_field = self.content_model.content_model_fields.core_fields('belongs_to')[0]
        self.content_model_field_id = core_field.id
        self.content_model_field_name = core_field.field
      else
        self.content_model_field_name = nil
        self.content_model_field_id = nil
      end
    end
  end

  # Return all fields except the one we're using for linking
  def display_content_model_fields
    if self.content_model
      self.content_model.content_model_fields.select { |fld| fld.id != self.content_model_field_id }
    else
      []
    end
  end


  def validate
    if self.content_model && self.content_model_field_id.blank?
      self.errors.add(:content_model_id,"needs to have a valid belongs to field")
    end
  end

end
