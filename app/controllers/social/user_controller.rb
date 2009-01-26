

class Social::UserController < ParagraphController

  editor_header 'Social Networking Paragraphs'

  editor_for :view_profile, :name => 'View User Profile', :inputs => [ [ :user_id, 'Profile User Id', :path ] ], :features => [ :social_view_profile ], :outputs => [ [:user,'Public Profile User',:target ], [:user_private,'Private Profile User',:target ], [:social_user,"Social User Private",:target], [:containers,"Target List",:target_list ]]
  
  editor_for :edit_profile, :features => [ :social_user_edit_profile ]

  editor_for :friends, :name => 'User Friends', :inputs => [[ :user_id, 'User Id', :path ], [:user, 'Profile User',:target ]] , :features => [ :social_friends ]
  
  editor_for :friend_groups, :name => 'Friend Groups', :inputs => [[ :user_id, 'User Id', :path ], [:user, 'Profile User',:target ]] , :features => [ :social_user_friend_groups ]
  
  editor_for :user_search, :name => 'User Search', :features => [ :social_user_search ]
  
  class ViewProfileOptions < HashModel
    attributes :social_unit_type_id => nil, :group_page_id => nil
    
    integer_options :social_unit_type_id,:group_page_id
    
    page_options :group_page_id
  end

  def edit_profile
    @options = EditProfileOptions.new(params[:edit_profile] || paragraph.data || {})
    
    return if handle_paragraph_update(@options)
    
    opts = Social::AdminController.module_options
    
    @publications = ContentPublication.find_select_options(:all,:conditions => { :publication_type => 'edit', :content_model_id => opts.user_model_id })    
    
  
  end

  class EditProfileOptions < HashModel
    attributes :content_publication_id => nil, :profile_page_id => nil
    
    integer_options :content_publication_id, :profile_page_id
    page_options :profile_page_id
  end
  
  
  
  class FriendOptions < HashModel
    attributes :profile_page_id => nil, :limit => 0, :grouped => 'no',:order => 'newest'
    
    validates_numericality_of :limit
    
    integer_options :limit, :profile_page_id
    
    validates_presence_of :profile_page_id, :grouped
    
    has_options :order, [['Newest','newest'],['Oldest','oldest'],['Alphabetical','alpha']]
  end
  
  class UserSearchOptions < HashModel
    attributes :social_unit_type_id => nil, :social_unit_parent_type_id => nil, :profile_page_id  => nil, :social_unit_type_id => nil, :profile_id => nil
    
    integer_options :social_unit_type_id,:social_unit_parent_type_id,:profile_page_id
    
    page_options :profile_page_id
  end
  
  class FriendGroupOptions < HashModel
    attributes :social_unit_type_id => nil, :friends_page_id => nil, :parent => true, :limit => 0
    
    integer_options :limit
    boolean_options :parent
    page_options :friends_page_id
  end
end
