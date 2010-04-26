
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
    
    outstanding_invite = false
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
      @groups = SocialUnitMember.member_groups(@user.id).group_by(&:social_unit_type_id)
      @group_types = @groups.group_by(&:social_unit_type_id)

      @primary_group = @groups[@options.social_unit_type_id][0] if @groups[@options.social_unit_type_id]
    else
      @groups = []
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
    
    if !ajax?
      conn_type,conn_id = page_connection
      
      if conn_type == :user_id
        @user = EndUser.find_by_id(conn_id)
      elsif conn_type == :user
        @user = conn_id      
      else
        @user = myself
      end
      
      if request.post? && params[:remove_friend] && @user == myself
        if SocialFriend.remove_friend(myself,EndUser.find_by_id(params[:remove_friend]))
          redirect_paragraph paragraph_page_url
          return
        end
      end
      
      if !@user 
        render_paragraph :text => ''
        return
      end
      
      if @options.grouped == 'yes'
        @suser = social_user(@user)
        groups = @suser.social_units

        order = { 'newest' => 'created_at DESC','oldest' => 'created_at','alpha' => 'end_users.last_name,end_users.first_name' }[@options.order]
        limit =@options.limit.to_i > 0 ? @options.limit.to_i : nil
        
        friends = groups.collect do |group|
          [ group, group.user_friends(@user,:order => order,:limit => limit) ]
        end
        
        limit =@options.limit.to_i > 0 ? @options.limit.to_i : nil
        
        friends << [ nil, SocialFriend.find(:all,:conditions => ['end_user_id=? AND social_unit_id IS NULL',@user.id],:joins => :end_user,:order => order, :limit => limit).map { |sf| sf.friend_user }.compact ]
      else
        limit =@options.limit.to_i > 0 ? @options.limit.to_i : nil
        
        if params[:group_id]
          group = SocialUnit.find_by_id(params[:group_id])
          friends = [[ group, SocialUnitMember.find(:all,:conditions => { :end_user_id => SocialFriend.friends_cache(@user), :social_unit_parent_id => params[:group_id] }, :include => :end_user).map { |su| su.end_user }.compact ] ]
        else
          friends = [ [ nil, SocialFriend.find(:all,:conditions => ['end_user_id=?',@user.id],:joins => :end_user,:order => order, :limit => limit,:order => order).map { |sf| sf.friend_user }.compact ] ]
        
        end
      end
      
      data = { :friends => friends, :profile_url => SiteNode.node_path(@options.profile_page_id), :user => @user, :group => group }
      
      render_paragraph :text => social_friends_feature(data)
    end
  end
  
  def friend_groups
  
    @options = paragraph_options(:friend_groups)
    
    conn_type,conn_id = page_connection
    
    if conn_type == :user_id
      @user = EndUser.find_by_id(conn_id)
    elsif conn_type == :user
      @user = conn_id      
    end
    
    if !@user 
      @user = myself
    end
    
    
    @suser = social_user(@user)
    
    friends = SocialFriend.friends_cache(@user)
    groups  = SocialUnitMember.count(:all,:conditions => { :end_user_id => friends, :social_unit_type_id => @options.social_unit_type_id }, :group => @options.parent ? :social_unit_parent_id : :social_unit_id)
    
    
    units = SocialUnit.find(:all,:conditions => { :id => groups.map { |elm| elm[0] } } ).index_by(&:id)
    
    groups_data = groups.collect do |group|
      if units[group[0].to_i]
        [ units[group[0].to_i], group[1] ]
      else
        nil
      end
    end.compact

    groups_data.sort! { |a,b| b[1] <=> a[1] }
    if @options.limit.to_i > 0
      groups_data = groups_data.slice(0..@options.limit.to_i)
    end

    
    data = { :user => @user, :groups => groups_data, :friends_page_url => @options.friends_page_url }
        
    render_paragraph :text => social_user_friend_groups_feature(data)
  end
  
  def user_search
  
    @options = paragraph_options(:user_search)
    @suser = social_user(myself)
    
    if params[:search] && !params[:search][:name].blank?
      full_name = params[:search][:name].strip
      first_name,last_name = full_name.split(" ").map { |e| e=e.strip.downcase; e.blank? ? nil : e }.compact
      
      if first_name && last_name
        @conditions = '(first_name LIKE ? AND last_name LIKE ?)'
        @condition_opts = [ "%#{first_name}%", "%#{last_name}%" ]
      else
        @conditions = '(first_name LIKE ? OR last_name LIKE ?)'
        @condition_opts = [ "%#{first_name}%", "%#{first_name}%" ]
      end
      
      if @options.profile_id.to_i > 0
        @conditions += " AND user_class_id = ?"
        @condition_opts << @options.profile_id.to_i
      end
      
      if params[:search][:where].blank? || params[:search][:where].to_s == 'all' 
         paging,results = EndUser.paginate(:all,:conditions => [@conditions] + @condition_opts)
      elsif params[:search][:where] == 'national'
         @group = @suser.social_units(@options.social_unit_type_id)[0]
         paging,results = EndUser.paginate(:all,:conditions => [@conditions + " AND social_unit_parent_id=?"] + @condition_opts + [@group ? @group.parent_id : 0] , :joins => ' LEFT OUTER JOIN social_unit_members ON (social_unit_members.end_user_id = end_users.id)')
      else params[:search][:where] == 'member'
         @group = @suser.social_units(@options.social_unit_type_id)[0]         
         paging,results = EndUser.paginate(:all,:conditions => [@conditions + " AND social_unit_id = ?"] + @condition_opts + [@group ? @group.id : 0], :joins => ' LEFT OUTER JOIN social_unit_members ON (social_unit_members.end_user_id = end_users.id)' )
      end
      end_user_ids = []
      results.each { |user| end_user_ids << user.id; }
      groups = []
      if results.length > 0
        groups = SocialUnitMember.find(:all,:conditions => [ 'end_user_id IN (?) AND social_unit_members.social_unit_type_id=?',end_user_ids,@options.social_unit_type_id ], :include => :social_unit ).group_by(&:end_user_id)
      end
      
      results.map! { |user| end_user_ids << user.id; { :user => user, :groups => groups[user.id]||[] } }
    end
    data = {:search => params[:search], :results => results, :paging => paging, :profile_page => @options.profile_page_url }
    require_social_js

    render_paragraph :text => social_user_search_feature(data)
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
