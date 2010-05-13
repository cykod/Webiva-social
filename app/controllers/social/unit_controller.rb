

class Social::UnitController < ParagraphController

  editor_header 'Social Networking Paragraphs'
  
  editor_for :location, :name => 'Group List Display ', :feature =>  :social_unit_location, :inputs => [ [:location_id,"Location Id",:path ]] 

  editor_for :group_join, :name => 'Join a group List', :feature => :social_unit_group_join
  
  editor_for :create_group, 'name' => 'Create Group', :features => [ :social_unit_create_group ]
  
  editor_for :group, :name => 'Group Display',
    :outputs => [ [:group,'Group Public Target',:target ], 
                  [:group_private,'Group Private Target',:target], 
                  [:group_admin,'Group Admin Target',:target], 
                  [:social_unit,'Social Unit Public',:social_unit ], 
                  [:social_unit_private,'Social Unit Private',:social_unit], 
                  [ :group_id, 'Group Id', :integer ] ],
    :inputs => [ [ :group_id, 'Group URL', :path ], [ :group, "Group Target", :social_unit] ], :features => [ :social_unit_group]
  
  editor_for :edit_group, :name => 'Edit Group', :features => [ :social_unit_edit_group ], :inputs => [ [ :group_id, 'Group Id', :path ] ]
  
  editor_for :members, :name => 'Members Display', :inputs => [ [ :group_id, 'Group URL', :path ], [:social_unit,'Social Unit Public',:social_unit ] ], :features => [[ :social_unit_members ]] 
  
  
  editor_for :member_location, :name => 'Member Locations', :inputs => [ [ :group_id, 'Group ID', :path ], [:social_unit,'Social Public',:social_unit ] ], :features => [[ :social_unit_member_location ]] 
  



  class LocationOptions < HashModel
    attributes :display => 'none', :group_page_id => nil,:social_unit_type_id => 0
    
    page_options :group_page_id
    
    has_options :display, [['No location','none'],['User Location','own'],['Page Connection','connection']]
  end


  class GroupJoinOptions < HashModel
    attributes :social_unit_type_id => 0, :joined_page_id => nil

    page_options :joined_page_id

    options_form( 
          fld(:social_unit_type_id, :select, :options => Proc.new { SocialUnitType.select_options_with_nil("Group") }),
          fld(:joined_page_id, :page_selector))
  end
  
  class GroupOptions < HashModel
    attributes :social_unit_type_id => 0,:display_type => 'both', :child_member => false, :edit_page_id => 0, :base_page_id => nil
    has_options :display_type, [['Page connection or Member','both'],['Page connection','page'],['Member only','member']]

    page_options :base_page_id, :edit_page_id
    boolean_options :child_member

    canonical_paragraph "SocialUnitType", :social_unit_type_id

    def social_unit_type
      @social_unit_type ||= SocialUnitType.find_by_id(self.social_unit_type_id)
    end


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
    attributes :social_unit_type_id => 0, :invalid_page_id => 0, :content_publication_id => 0, :success_page_id => 0, :display_fields => [ 'name', 'image_file']
    
    page_options :success_page_id, :invalid_page_id

    validates_presence_of :social_unit_type_id

    def social_unit_type
      @social_unit_type ||= SocialUnitType.find_by_id(self.social_unit_type_id)
    end

    def available_publications
      ContentPublication.select_options_with_nil(nil,:conditions => { :publication_type => 'create', :content_model_id => self.social_unit_type.content_model_id })
    end

    def valid_field_parameters
      flds = self.available_field_list

      [ :entry ] + self.display_fields.map { |fld| flds[fld.to_sym][2] }
    end

    def publication
      @publication ||= ContentPublication.find_by_id(self.content_publication_id)
    end

    def available_field_list
      { :name => [ 'Name'.t,:text_field,:name ],
        :image_file => [ "Image".t,:upload_image,:image_file_id],
        :address =>  [ 'Address'.t,:text_field,:address, { :no_label => true } ],
        :city =>  [ 'City'.t,:text_field,:city ],
        :state =>  [ 'State'.t,:text_field,:state ],
        :zip =>  [ 'Zip'.t,:text_field,:zip ],
        :website=>  [ 'Website'.t,:text_field,:website ]
      }
    end

    def ordered_field_list
      flds = self.available_field_list
      
      self.display_fields.map do |fld|
        field_data = flds[fld.to_sym]
        if field_data
          field_data[3] ||= {}
          [ fld.to_sym ] + field_data
        end
      end.compact
    end

    def available_field_names
      self.available_field_list.to_a.map { |elm| elm[1][2] }
    end

    def available_field_options
      self.available_field_list.map { |elm| [ elm[1][0], elm[0].to_s ] }
    end
  end
  
  class MembersOptions < HashModel
    attributes :profile_page_id =>nil, :per_page => 10, :status => '', :profile_type_id => nil
    page_options :profile_page_id 
    validates_presence_of :profile_type_id

      options_form(
        fld(:profile_page_id,:page_selector),
        fld(:profile_type_id,:select,:options => lambda { UserProfileType.select_options_with_nil },:required => true),
        fld(:status,:text_field,:description => 'Only show members with this status'),
        fld(:per_page,:text_field),
        fld(:approved,:check_box,:description => 'only show approved members'))
        
    
    
  end
  
  class MemberLocationOptions < HashModel
      attributes :group_page_id => nil, :limit => 5
      integer_options :limit  
      page_options :group_page_id


  end
  
end
