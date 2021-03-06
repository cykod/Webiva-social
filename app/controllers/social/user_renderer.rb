
class Social::UserRenderer < Social::SocialRenderer

  features '/social/user_feature'
  features '/social/message_feature'

  paragraph :view_profile
  
  paragraph :wall
  paragraph :friends
  paragraph :user_search
  paragraph :friend_groups

  def view_profile
    @options = paragraph_options(:view_profile)
    @mod_opts = module_options(:social)
    

    @user, @user_profile = fetch_profile
    
    @outstanding_invite = false
    if @user
      @is_friend = SocialFriend.is_friend?(myself,@user) 
      
      if !@is_friend
        @outstanding_invite = SocialFriend.has_invite?(myself,@user)
      end
      @is_myself = myself.id == @user.id 
    end

    @suser = social_user(@user) if @user
    
    @private_view = true  if @is_friend || @is_myself

    if @user_profile
      @content_model = @user_profile.content_model
      set_title(@user.full_name)
      set_title(@user.full_name,"profile")
    end

    set_page_connection(:user_private,@private_view ? @user : nil) 
    set_page_connection(:user,@user)
    set_page_connection(:user_profile_entry,@user_profile)
    set_page_connection(:user_profile_entry_private,@private_view ? @user_profile: nil)
    set_page_connection(:social_user,@suser)
    set_page_connection(:content_list,@suser ? @suser.nested_full_content_list : nil)
    set_page_connection(:content_list_private,@private_view ? @suser.nested_full_content_list : nil)

    set_page_connection(:profile_content, @user_profile ? ['UserProfileEntry',@user_profile.id] : nil)
    set_content_node(@user_profile)
    
    if @user && @options.include_groups
      @groups = SocialUnitMember.member_groups(@user.id)
      set_page_connection(:group_list,@groups.map(&:social_unit)) 
      @group_types = @groups.group_by(&:social_unit_type_id)
      @primary_group = @group_types[@options.social_unit_type_id][0] if @group_types[@options.social_unit_type_id]

      @is_group_admin = @primary_group.social_unit.is_admin?(myself) if @primary_group
    else
      @groups = []
      set_page_connection(:group_list,[]) 
      @group_types = {}
      @primary_group = nil
    end

    require_social_js
    
    render_paragraph :text => social_view_profile_feature
  end


  def fetch_profile
    connection_type,conn_id = page_connection
    
    if(!conn_id.blank?)
      @user_profile = UserProfileEntry.find_published_profile(conn_id,@options.profile_type_id)
      @user = @user_profile.end_user if @user_profile
      
      if @user && SocialBlock.blocked?(myself,@user)
        @blocked = true
        @user = nil 
        @user_profile = nil
      end
    elsif myself.id
      @user = myself
      @user_profile = UserProfileEntry.fetch_entry(@user.id,@options.profile_type_id)
    end

    [ @user, @user_profile ]
  end
  
  def friends
    @options = paragraph_options(:friends)
    @user = get_user_from_page_connection

    if request.post? && params[:remove_friend] && @user == myself
      if SocialFriend.remove_friend(myself,EndUser.find_by_id(params[:remove_friend]))
        redirect_paragraph paragraph_page_url
        return
      end
    end

    return render_paragraph :text => '' if !@user
    @suser = social_user(@user)
    @is_myself = @user == myself 

    result = renderer_cache(@suser,@is_myself ? 'myself' : 'other') do |cache|
      limit =@options.limit.to_i > 0 ? @options.limit.to_i : nil

      friend_users = SocialFriend.friends_cache(@user)
      friend_users = friend_users[0..limit-1] if limit
      @friends = UserProfileEntry.fetch_entries(friend_users)

      @profile_url = @options.profile_page_url
      cache[:output] = social_friends_feature
    end

    render_paragraph :text => result.output
  end


  def get_user_from_page_connection
    conn_type,conn_id = page_connection
    if conn_type == :user_url
      profile = UserProfileEntry.find_published_profile(conn_id,@options.profile_type_id)
      user = profile.end_user if profile
    elsif conn_type == :user
      conn_id      
    else
      myself
    end
  end
  
  def user_search
  
    @options = paragraph_options(:user_search)
    @suser = social_user(myself)
    
    if params[:search] && !params[:search][:name].blank?
      
      cnv, count = ContentNodeValue.search(Configuration.languages[0],params[:search][:name],
                              { :conditions => { :content_type_id => @options.user_profile_type.content_type.id }})

      content_nodes = cnv.map(&:content_node)

      @results = UserProfileEntry.find(:all, :conditions => { :id => content_nodes.map(&:node_id) }, :include => :end_user).reject { |e| e.end_user.blank? }

    end

    render_paragraph :text => social_user_search_feature
  end

  def user_edit
    connection_type,conn_id = page_connection
    
    if(!conn_id.blank?)
      @user_profile = UserProfileEntry.find_published_profile(conn_id,@options.profile_type_id)

    end

    @options = paragraph_options(:view_profile)
    @mod_opts = module_options(:social)
    

    @user, @user_profile = fetch_profile
    
    @outstanding_invite = false
    if @user
      @is_friend = SocialFriend.is_friend?(myself,@user) 
      
      if !@is_friend
        @outstanding_invite = SocialFriend.has_invite?(myself,@user)
      end
      @is_myself = myself.id == @user.id 
    end

    @suser = social_user(@user) if @user
    
    @private_view = true  if @is_friend || @is_myself

    if @user_profile
      @content_model = @user_profile.content_model
      set_title(@user.full_name)
      set_title(@user.full_name,"profile")
    end

    set_page_connection(:user_private,@private_view ? @user : nil) 
    set_page_connection(:user,@user)
    set_page_connection(:user_profile_entry,@user_profile)
    set_page_connection(:user_profile_entry_private,@private_view ? @user_profile: nil)
    set_page_connection(:social_user,@suser)
    set_page_connection(:content_list,@suser ? @suser.nested_full_content_list : nil)
    set_page_connection(:content_list_private,@private_view ? @suser.nested_full_content_list : nil)

    set_page_connection(:profile_content, @user_profile ? ['UserProfileEntry',@user_profile.id] : nil)
    set_content_node(@user_profile)
    
    if @user && @options.include_groups
      @groups = SocialUnitMember.member_groups(@user.id)
      set_page_connection(:group_list,@groups.map(&:social_unit)) 
      @group_types = @groups.group_by(&:social_unit_type_id)
      @primary_group = @group_types[@options.social_unit_type_id][0] if @group_types[@options.social_unit_type_id]
    else
      @groups = []
      set_page_connection(:group_list,[]) 
      @group_types = {}
      @primary_group = nil
    end

    require_social_js
    
    render_paragraph :text => social_view_profile_feature
  end



  def require_social_js
    require_js('prototype.js')
    require_js('builder')
    require_js('redbox')
    require_css('redbox')        
    require_js('effects.js')
    require_js('controls.js')
    require_js('user_application.js')
    require_js('end_user_table.js')    
  end

end
