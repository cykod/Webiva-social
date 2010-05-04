

class Social::UserController < ParagraphController

  editor_header 'Social Networking Paragraphs'

  editor_for :view_profile, :name => 'View User Profile', :inputs => [ [ :profile_entry_url, 'Profile User URL', :path ] ], :feature =>  :social_view_profile, 
    :outputs => [ [:user,'Public Profile User',:target ], 
                  [:user_private,'Private Profile User',:target ], 
                  [:user_profile_entry, 'Public Profile Entry', :target],
                  [:user_profile_entry_private, 'Private Profile Entry', :target],
                  [:social_user,"Social User Private",:target], 
                  [:content_list,"Friend and Group List",:content_list ],
                  [:content_list_private,"Friend and Group list Private",:content_list] ]
  
  editor_for :friends, :name => 'User Friends', :inputs => [[ :user_url, 'User Profile URL', :path ], [:user, 'Profile User',:target ]] , :features => [ :social_friends ]
  
  editor_for :friend_groups, :name => 'Friend Groups', :inputs => [[ :user_id, 'User Id', :path ], [:user, 'Profile User',:target ]] , :features => [ :social_user_friend_groups ]
  
  editor_for :user_search, :name => 'User Search', :features => [ :social_user_search ]
  
  class ViewProfileOptions < HashModel
    attributes :social_unit_type_id => nil, :group_page_id => nil, :profile_type_id => nil,:include_groups => true
    page_options :group_page_id

    validates_presence_of :profile_type_id

    canonical_paragraph "UserProfileType", :profile_type_id

    options_form fld(:social_unit_type_id,:select,:options => :social_unit_types, :label => 'Primary Group Type'),
                 fld(:group_page_id,:page_selector, :label => 'Primary Group Page'),
                 fld(:profile_type_id,:select, :options => :profile_type_options),
                 fld(:include_groups,:yes_no)

    def social_unit_types; SocialUnitType.select_options_with_nil; end
    def profile_type_options; UserProfileType.select_options_with_nil; end
  end

  class FriendsOptions < HashModel
    attributes :profile_page_id => nil, :profile_type_id => nil, :limit => 0, :order => 'newest'
    validates_numericality_of :limit
    integer_options :limit, :profile_page_id
    validates_presence_of :profile_page_id, :profile_type_id
    boolean_options :grouped
    page_options :profile_page_id
    has_options :order, [['Newest','newest'],['Oldest','oldest'],['Alphabetical','alpha']]

   options_form(
      fld(:profile_type_id,:select, :options => Proc.new {  UserProfileType.select_options_with_nil }, :required => true),
      fld(:profile_page_id,:page_selector,:required => true),
      fld(:limit,:text_field,:label => 'Limit', :description => '0 for all (per group if grouped)'),
      fld(:order,:select,:options => :order_select_options)
   )
    
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

    def profile_type_options; UserProfileType.select_options_with_nil; end

  end
end
