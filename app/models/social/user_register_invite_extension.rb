

class Social::UserRegisterInviteExtension < Handlers::ParagraphFormExtension
  
  def self.editor_auth_user_register_feature_handler_info
    { 
      :name => 'Social Unit Invite  Registration',
      :paragraph_options_partial => '/social/handler/auth_user_invite_register'
    }
  end


  

  # Paragraph Setup options
  def self.paragraph_options(val={ })
    opts = UserRegisterExtensionParagraphOptions.new(val)
  end

  


  # Generates called with the paragraph parameters
  def generate(params)
    @feature_obj = RegistrationOptions.new(params[:user] ? params[:user].slice(:email) : { })
    @feature_obj
  end

  # Called before the feature is displayed
  def feature_data(data)
    data[:social_invite_extension] = @feature_obj
  end

  # Adds any feature related tags
  def feature_tags(c,data)
    c.value_tag('invite_error') {  |t| data[:social_invite_extension].errors.full_messages.join("<br/>")}
    c.expansion_tag('invite_missing') { |t| data[:social_invite_extension].errors.on(:email)}
    c.expansion_tag('invite_limit') { |t| data[:social_invite_extension].errors.on(:limit)}
  end

  # Validate the submitted data
  def valid?
    invite = SocialInvite.find_by_email(@feature_obj.email)
    if !invite
      @feature_obj.errors.add(:email,'does not match an existing invitation')
      false
    else
      if invite.social_unit.social_unit_members.length > @options.limit
        @feature_obj.errors.add(:limit,"has been reached for this account")
      false
      else
        true
      end
    end
  end

  # After everything has been validated 
  # Perform the actual form submission
  def post_process(user)
    invite = SocialInvite.find_by_email(@feature_obj.email)

    if invite && invite.social_unit
      invite.social_unit.add_member(user,'member','member')
    end
  end


  class UserRegisterExtensionParagraphOptions < HashModel
    attributes :social_unit_type_id => nil, :limit => 10

   validates_numericality_of :limit
    integer_options :social_unit_type_id, :limit

  end

  class  RegistrationOptions < HashModel
    attributes :email => nil,:limit => nil

    
  end

  

end
