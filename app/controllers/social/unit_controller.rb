

class Social::UnitController < ParagraphController

  editor_header 'Social Networking Paragraphs'
  
  editor_for :location, :name => 'Location Display', :features => [ :social_unit_location ], :inputs => [ [:location_id,"Location Id",:path ]] 
  
  editor_for :create_group, 'name' => 'Create Group', :features => [ :social_unit_create_group ]
  
  editor_for :group, :name => 'Group Display', :outputs => [ [:group,'Group Public Target',:target ], [:group_private,'Group Private Target',:target], [:group_admin,'Group Admin Target',:target], [:social_unit,'Social Unit Public',:social_unit ], [:social_unit_private,'Social Unit Private',:social_unit], [ :group_id, 'Group Id', :integer ] ], :inputs => [ [ :group_id, 'Group Id', :path ] ], :features => [ :social_unit_group]
  
  editor_for :edit_group, :name => 'Edit Group', :features => [ :social_unit_edit_group ], :inputs => [ [ :group_id, 'Group Id', :path ] ]
  
  editor_for :members, :name => 'Members Display', :inputs => [ [ :group_id, 'Group ID', :path ], [:social_unit,'Social Unit Public',:social_unit ] ], :features => [[ :social_unit_members ]] 
  
  
  editor_for :member_location, :name => 'Member Locations', :inputs => [ [ :group_id, 'Group ID', :path ], [:social_unit,'Social Public',:social_unit ] ], :features => [[ :social_unit_member_location ]] 
  
  class LocationOptions < HashModel
    attributes :display => 'own', :group_url_id => nil,:social_unit_type_id => 0
    
    integer_options :group_url_id, :social_unit_type_id
    validates_numericality_of :group_url_id
    
    has_options :display, [['User Location','own'],['Page Connection','connection']]
  end
  
  class GroupOptions < HashModel
    attributes :social_unit_type_id => 0,:display_type => 'both', :child_member => false, :edit_page_id => 0
    has_options :display_type, [['Page connection or Member','both'],['Page connection','page'],['Member only','member']]
    integer_options :social_unit_type_id, :edit_page_id
    boolean_options :child_member
  end
  
  def edit_group
  
    @options = EditGroupOptions.new(params[:edit_group] || paragraph.data || {})
    
    return if handle_paragraph_update(@options)
    
    if @options.social_unit_type_id.to_i > 0  
      @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id)
    end
  end
  
  class CreateGroupOptions < HashModel
    attributes :social_unit_type_id => 0, :success_page_id => 0
    
    integer_options :social_unit_type_id,:success_page_id
    page_options :success_page_id
  end
  
  class EditGroupOptions < HashModel
    attributes :social_unit_type_id => 0, :invalid_page_id => 0, :content_publication_id => 0, :success_page_id => 0
    integer_options :social_unit_type_id, :invalid_page_id, :content_publication_id, :success_page_id
    
    page_options :success_page_id
  end
  
  class MembersOptions < HashModel
    attributes :profile_page_id =>nil, :per_page => 10, :status => ''
    
    integer_options :profile_page_id
    
  end
  
  class MemberLocationOptions < HashModel
      attributes :group_page_id => nil, :limit => 5
      integer_options :limit  
      page_options :group_page_id
  end
  
end
