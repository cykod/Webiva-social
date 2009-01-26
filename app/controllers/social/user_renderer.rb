
class Social::UserRenderer < Social::SocialRenderer

  features '/social/user_feature'
  features '/social/message_feature'

  paragraph :edit_profile
  paragraph :view_profile
  
  paragraph :wall
  paragraph :friends
  paragraph :user_search
  paragraph :friend_groups

  def edit_profile
    @options = paragraph_options(:edit_profile)
    @mod_opts = module_options(:social)
    @user = myself
    @suser = social_user(@user)
    
    content_model = ContentModel.find_by_id(@mod_opts.user_model_id)
    cls = content_model.content_model
    entry = cls.find_by_user_id(@user.id) || cls.new(:user_id => @user.id)
    publication = content_model.content_publications.find_by_id(@options.content_publication_id)
    
    if params[:user]
    
      handle_image_upload(params[:user],:domain_file_id, :location => Configuration.options[:user_image_folder])

      @user.attributes = params[:user]
      entry.attributes = params[:entry]
      
      if @user.valid? && entry.valid?
        if params[:suser] && params[:suser][:role] && Social::AdminController.module_options.roles.include?(params[:suser][:role])
          @suser.update_attribute(:role,params[:suser][:role])
          @suser.update_member_roles(params[:suser][:role])
        end
        
        @user.save
        entry.save
        if @options.profile_page_id.to_i > 0
          redirect_paragraph @options.profile_page_url
        else
          render_paragraph :text => 'Your profile has been updated'
        end
        return        
      end          

    end
    
    frm = render_to_string :partial => '/social/user/edit_profile', :locals => { :entry => entry, :user => @user, :suser => @suser, :options => @options, :publication => publication }
    
    data = { :user => @user, :frm => frm, :publication => publication, :entry => entry, :suser => @suser }
  
    render_paragraph :text => social_user_edit_profile_feature(data)
  end 
  
  
  def view_profile
    @options = paragraph_options(:view_profile)
    @mod_opts = module_options(:social)
    
    content_model = ContentModel.find_by_id(@mod_opts.user_model_id)
    cls = content_model.content_model 

    connection_type,conn_id = page_connection
    
    if(!conn_id.blank?)
      @user = EndUser.find_by_id(conn_id)
      
      if @user && SocialBlock.blocked?(myself,@user)
        @blocked = true
        @user = nil 
      end
    else
      @user = myself
    end
    
    outstanding_invite = false
    if @user
      is_friend = SocialFriend.is_friend?(myself,@user) 
      
      if !is_friend
        outstanding_invite = SocialFriend.has_invite?(myself,@user)
      end
      is_myself = myself.id == @user.id 
    end

    @suser = social_user(@user) if @user
    
    set_page_connection(:user_private,@user) if is_friend || is_myself
    set_page_connection(:user,@user)
    set_page_connection(:social_user,@suser)
    
    
    set_page_connection(:containers,@suser)
    
    
    @entry = cls.find_by_user_id(@user.id) || cls.new(:user_id => @user.id) if @user
    
    if @user
      @all_members = SocialUnitMember.find(:all,:conditions => { :end_user_id => @user.id}).group_by(&:social_unit_type_id)
      @social_unit_members = @all_members[@options.social_unit_type_id] || []
    else
      @all_members = {}
      @social_unit_members = []
    end
    
    
    data = { :user => @user, :entry => @entry, :content_model => content_model, :suser => @suser,
             :social_unit_members =>  @social_unit_members, :myself => is_myself,
             :groups => @all_members, :group_page_url => @options.group_page_url,
             :private => is_friend || is_myself, :friend => is_friend, :blocked => @blocked,
             :outstanding_invite => outstanding_invite }
    
    render_paragraph :text => social_view_profile_feature(data)
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

  require_js('prototype.js')
      require_js('builder')
      require_js('redbox')
      require_css('redbox')        
      require_js('effects.js')
      require_js('controls.js')
      require_js('user_application.js')
      require_js('end_user_table.js')    
        
  
    render_paragraph :text => social_user_search_feature(data)
  end

end
