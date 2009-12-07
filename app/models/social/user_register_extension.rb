

class Social::UserRegisterExtension < Handlers::ParagraphFormExtension
  
  def self.editor_auth_user_register_feature_handler_info
    { 
      :name => 'Social Unit Registration',
      :paragraph_options_partial => '/social/handler/auth_user_register'
    }
  end


  

  # Paragraph Setup options
  def self.paragraph_options(val={ })
    opts = UserRegisterExtensionParagraphOptions.new(val)
  end

  


  # Generates called with the paragraph parameters
  def generate(params)
    @feature_obj = RegistrationOptions.new(params[:social] || { })
    @feature_obj.options = @options
    @feature_obj
  end

  # Called before the feature is displayed
  def feature_data(data)
    data[:social_extension] = @feature_obj
  end

  # Adds any feature related tags
  def feature_tags(c,data)
    c.fields_for_tag('register:social','social') { |t| data[:social_extension]}
    c.field_tag('register:social:name')
    c.field_tag('register:social:website')
  end

  # Validate the submitted data
  def valid?
    @feature_obj.valid?
  end

  # After everything has been validated 
  # Perform the actual form submission
  def post_process(user)
    @unit = SocialUnit.create(
                              :name => @feature_obj.name.to_s.strip, 
                              :website => @feature_obj.website.to_s.strip.downcase,
                              :social_unit_type_id => @options.social_unit_type_id,
                              :created_by_id => user.id,
                              :approved => @options.approved,
                              :approved_until => @options.approved_until)
    @unit.add_member(user,'member','admin')
  end


  class UserRegisterExtensionParagraphOptions < HashModel
    attributes :social_unit_type_id => nil, :approved => false, :approved_for_days => 0

    boolean_options :approved
    integer_options :social_unit_type_id, :approved_for_days

    def approved_until
      if self.approved_for_days > 0
        self.approved_for_days.days.from_now
      else
        nil
      end
    end


    validates_numericality_of :approved_for_days
    validates_presence_of :social_unit_type_id
  end

  class  RegistrationOptions < HashModel
    attributes :name => nil, :website => nil,:options => nil

    validates_presence_of :name

    validates_format_of :website, :with => /^https?\:\/\/.+/, :message => 'should be a full-url beginning with http'

    def validate
      if SocialUnit.find_by_name_and_social_unit_type_id(self.name.to_s.strip,self.options.social_unit_type_id)
        self.errors.add(:name,'already exists in the system')
      end
      if SocialUnit.find_by_website_and_social_unit_type_id(self.website.to_s.strip.downcase,self.options.social_unit_type_id)
        self.errors.add(:website,'already exists in the system')
      end
    end
  end

  

end
