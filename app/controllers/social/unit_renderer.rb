

class Social::UnitRenderer < Social::SocialRenderer
  include ActionView::Helpers::FormOptionsHelper

  features '/social/unit_feature'

  paragraph :location, :ajax => true
  paragraph :group
  paragraph :edit_group
  paragraph :members
  paragraph :gallery_upload, :ajax => true
  paragraph :create_group
  paragraph :member_location

  def location
    @options = paragraph_options(:location)
    
    if ajax?
      @locs = [['--Select Location--',nil]] + SocialLocation.select_options(:conditions => ['state=?',params[:select][:state]],:order =>'name')
        
      render_paragraph :text => "<select id='select_location' name='select[location]' onchange=\"if(this.value!='') document.location = '#{site_node.node_path}/' + this.value;\">" + options_for_select(@locs) + "</select>"
    else
      @suser = social_user(myself)
      if params[:select]
        @loc = SocialLocation.find_by_id(params[:select][:location])
        if @loc
          redirect_paragraph site_node.node_path + "/" + @loc.id.to_s
          return
        end
      end
      
      conn_type,conn_id = page_connection
      @loc = SocialLocation.find_by_id(conn_id) if conn_id && conn_type == :location_id
        
      unless @loc      
        @loc = @suser.social_location
      end
      
      if @loc
        if @options.social_unit_type_id.to_i > 0
          @groups = @loc.social_units.find(:all,:order => 'name',:conditions => { :social_unit_type_id => @options.social_unit_type_id.to_i } )
        else
          @groups = @loc.social_units.find(:all,:order => 'name')
        end
      end
      
      state = @loc ? @loc.state : nil
      
      if state
        location_options = [['--Select Location--',nil]] + SocialLocation.select_options(:conditions => ['state=?',state],:order =>'name')
      else
        location_options = []
      end
    
      require_js('prototype.js')
      require_js('builder')
      require_js('redbox')
      require_css('redbox')        
      require_js('effects.js')
      require_js('controls.js')
      require_js('user_application.js')
      require_js('end_user_table.js')    
      
      data = { :location => @loc, :groups => @groups, :group_url => SiteNode.node_path(@options.group_url_id), :location_options => location_options, :selector => { :state => state, :location => (@loc ? @loc.id : nil)  }, :url => site_node.node_path }
      render_paragraph :text => social_unit_location_feature(data)
    end
  end

  def group

    
    @options = paragraph_options(:group)
    @suser = social_user(myself)
    
    @group = get_group
    
    set_page_connection(:group,@group)
    
    if @group && !@group.approved? && params[:request]
      SocialGroupRequest.register_request(myself,@group)
      @registered_request = true
    end

    is_member = @group && @group.is_member?(myself) ? true : false
    if @group && !is_member && @options.child_member
      is_member = @group && @group.is_child_member?(myself)
    end
    
    if is_member
      is_admin = @group.is_admin?(myself)
      
      if is_admin
        edit_page_url = SiteNode.node_path(@options.edit_page_id)
      end
      
    end

    set_page_connection(:group,@group)
    set_page_connection(:group_id,@group ? @group.id : nil) 
    set_page_connection(:group_private ,is_member ? @group : nil)
    set_page_connection(:group_admin ,is_admin ? @group : nil)
    set_page_connection(:social_unit,@group)
    set_page_connection(:social_unit_private ,is_member ? @group : nil)
    
    set_title(@group ? @group.name : 'None')
    set_title(@group ? @group.name : 'None','group')

    content_model = @group.social_unit_type.content_model if @group && @group.social_unit_type.content_model
    if content_model
     cls = content_model.content_model
     entry = cls.find_by_social_unit_id(@group.id) || cls.new(:social_unit_id => @group.id)
    end
    
    data = {:group => @group, :is_member => is_member, :is_admin => is_admin, :edit_page_url => edit_page_url, :content_model => content_model, :entry => entry ,:registered_request => @registered_request, :suser => @suser }
    

    render_paragraph :text => social_unit_group_feature(data)
  end
  
  
  def edit_group
    @suser = social_user(myself)
    @options = paragraph_options(:edit_group)

    @group = get_group
    
    is_admin = @group.is_admin?(myself.id) if @group
    
    if !is_admin && !editor?  &&  @options.redirect_page_id.to_i > 0
        redirect_paragraph :site_node => @options.redirect_page_id
    elsif is_admin
        @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id) unless @social_unit_type
        
        if @social_unit_type && @social_unit_type.content_model
          mdl = @social_unit_type.content_model
          publication = mdl.content_publications.find_by_id(@options.content_publication_id)
          cls = mdl.content_model
          entry = cls.find_by_social_unit_id(@group.id) || cls.new(:social_unit_id => @group.id)
        end
        
       if params[:group] && request.post?
          handle_image_upload(params[:group],:image_file_id, :location => Configuration.options[:user_image_folder])
          @group.attributes = params[:group]
          entry.attributes = params[:entry] if entry
          if @group.valid? && (!entry || entry.valid?)
            @group.save
            entry.save if entry
            
            if @options.success_page_id > 0
              redirect_paragraph @options.success_page_url + "/" + @group.id.to_s
            else
              render_paragraph :text => 'Group has been updated'
            end
            return
          end
        end
        
        frm = render_to_string :partial => '/social/unit/edit_group', :locals => { :entry => entry, :group => @group, :options => @options, :publication => publication }
        
        data = { :group => @group, :frm => frm }
    
        render_paragraph :text => social_unit_edit_group_feature(data)
    else
      render_paragraph :text => 'Invalid Group'
    end
  end
  
 def create_group
   @suser = social_user(myself)
   @options = paragraph_options(:create_group)

   @group = SocialUnit.new(:social_unit_type_id => @options.social_unit_type_id, :social_location_id => @suser.social_location_id)
    
   @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id) unless @social_unit_type
    
   if params[:group] && request.post?
      handle_image_upload(params[:group],:image_file_id, :location => Configuration.options[:user_image_folder])
      @group.attributes = params[:group].slice(:name,:image_file_id)
      if @group.valid? && @group.save
       @group.add_member(myself,'active','admin')
        
        if @options.success_page_id > 0
          redirect_paragraph "#{@options.success_page_url}/#{@group.id.to_s}"
        else
          render_paragraph :text => 'Group has been create'
        end
        return
      end
    end
    
    frm = render_to_string :partial => '/social/unit/create_group', :locals => { :group => @group, :options => @options, :location => @suser.social_location  }
      
    data = { :group => @group, :frm => frm, :location => @suser.social_location }
  
    render_paragraph :text => social_unit_create_group_feature(data)
  end  
  
  
  def members

    conn_type,conn_id = page_connection

    @suser = social_user(myself)

    if editor?
        @group = SocialUnit.find(:first)
    elsif conn_type == :group_id
      if conn_id.blank?
        @group = nil
      else
        @group = SocialUnit.find_by_id_and_level(conn_id,1)
      end
    elsif conn_type == :social_unit
      @group = conn_id
    end
    
    page = params[:page]
    options = paragraph_options(:members)
    @conds = ''
    @cond_opts = []
    if !options.status.blank?
      @conds += " AND status=?"
      @cond_opts << options.status
    end
    
    if @group
      @pages,@members = SocialUnitMember.paginate(page,:conditions => ['social_unit_id = ?' + @conds, @group.id ] + @cond_opts ,:per_page => options.per_page,:include => :end_user,:order =>' social_unit_members.created_at DESC')
      
      is_admin = @group.is_admin?(myself)
    end
    
    require_ajax_js

    data = { :admin => is_admin, :group => @group, :members => @members, :profile_url => SiteNode.node_path(options.profile_page_id), :pages => @pages  }
    render_paragraph :text => social_unit_members_feature(data)
  
  end
  
  def member_location

    @options = paragraph_options(:member_location)
    
    conn_type,conn_id = page_connection
    if conn_type == :group_id
      @unit = SocialUnit.find_by_id(conn_id)
    elsif conn_type == :social_unit
      @unit = conn_id
    end
    
    unless @unit
      render_paragraph :text => ''
      return
    end
    
    groups  = SocialUnitMember.count(:all,:conditions => { :social_unit_parent_id => @unit.id }, :group => :social_unit_id)
    
    
    units = SocialUnit.find(:all,:include => :social_location, :conditions => { :id => groups.map { |elm| elm[0] } } ).index_by(&:id)
    
    groups_data = groups.collect do |group|
      if units[group[0].to_i]
        [ units[group[0].to_i], units[group[0].to_i].social_location, group[1] ]
      else
        nil
      end
    end.compact

    groups_data.sort! { |a,b| b[2] <=> a[2] }
    if @options.limit.to_i > 0
      groups_data = groups_data.slice(0..@options.limit.to_i)
    end

    
    data = { :user => @user, :groups => groups_data, :group_page_url => @options.group_page_url }
        
    render_paragraph :text => social_unit_member_location_feature(data)
  
  end
  
 

  protected 
  
  def get_group
    conn_type,conn_id = page_connection

    if @options.social_unit_type_id > 0
      if editor?
          @group = SocialUnit.find(:first,:conditions => { :social_unit_type_id => @options.social_unit_type_id })
      elsif conn_type == :group_id || conn_id.blank?
        if conn_id.blank?
          @group = @suser.social_units(@options.social_unit_type_id)[0]
          if !@group && @options.child_member
            @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id)
            @child_group = @suser.social_units(@social_unit_type.child_type_id)[0]
            
            @group = @child_group.parent if @child_group
          end
        else
          @group = SocialUnit.find_by_id_and_social_unit_type_id(conn_id,@options.social_unit_type_id)
        end
      end
    else
      if editor?
          @group = SocialUnit.find(:first)
      elsif conn_type == :group_id || conn_id.blank?
        if conn_id.blank?
          @group = @suser.social_units[0]
        else
          @group = SocialUnit.find_by_id(conn_id)
        end
      end
    end
    
    @group
  end

end
