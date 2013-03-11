

class Social::UnitRenderer < Social::SocialRenderer
  include ActionView::Helpers::FormOptionsHelper

  features '/social/unit_feature'

  paragraph :location, :ajax => true
  paragraph :group
  paragraph :group_join
  paragraph :edit_group
  paragraph :members
  paragraph :create_group
  paragraph :member_location

  def location
    @options = paragraph_options(:location)
    
    if ajax?
      return render_locations_select
    end
    @suser = social_user(myself)
    if params[:select]
      @loc = SocialLocation.find_by_id(params[:select][:location])
      if @loc
        redirect_paragraph site_node.node_path + "/" + @loc.id.to_s
        return
      end
    end

    @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id) if @options.social_unit_type_id.to_i> 0
    @groups, @location = find_location_and_group

    require_ajax_js 

    @output = renderer_cache(SocialUnit,nil,:expires => 200) do |cache|

      cache[:feature] = social_unit_location_feature
    end

    @selector =  { :state => @state, :location => (@loc ? @loc.id : nil)  }
    render_paragraph :text => @output.feature
  end

  def render_locations_select
      @locs = [['--Select Location--',nil]] + SocialLocation.select_options(:conditions => ['state=?',params[:select][:state]],:order =>'name')
        
      render_paragraph :text => "<select id='select_location' name='select[location]' onchange=\"if(this.value!='') document.location = '#{site_node.node_path}/' + this.value;\">" + options_for_select(@locs) + "</select>"
  end


  def group_join
    @options = paragraph_options(:group_join)

    conds = {}
    conds[:social_unit_type_id] = @options.social_unit_type_id if @options.social_unit_type_id
    @groups = SocialUnit.find(:all,:conditions=>conds,:order => 'name')

    @groups = @groups.reject { |grp| grp.is_member?(myself) }

    if request.post? && params[:group]
      group_id = params[:group].to_i
      @group = @groups.detect { |grp| grp.id == group_id } 
      if @group
        @group.request_membership(myself)
        @added=true

        if @options.joined_page_url
          return redirect_paragraph @options.joined_page_url
        end
      end
    end


    render_paragraph :feature => :social_unit_group_join
  end

  def find_location_and_group
    conditions = { }
    conditions[:social_unit_type_id] = @options.social_unit_type_id if @options.social_unit_type_id.to_i > 0

    if @options.display == 'none'
      location = nil
    else
      conn_type,conn_id = page_connection
      location = SocialLocation.find_by_url(conn_id) if conn_id && conn_type == :location_id
   
      location = @suser.social_location unless location

      conditions[:social_location_id] = location.id if location

      @state = location ? location.state : nil

      @location_options = []
      @location_options = [['--Select Location--',nil]] + SocialLocation.select_options(:conditions => ['state=?',state],:order =>'name') if @state
    end
    groups = SocialUnit.find(:all,:conditions => conditions,:order => 'name')

    return groups,location
  end

  def group

    require_ajax_js 
    
    @options = paragraph_options(:group)
    @suser = social_user(myself)
    
    @group = get_group
    @social_unit_type = @group.social_unit_type if @group

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

    display_path = is_admin ? 'admin' : (is_member ? 'member' : 'anonymous' )

    result = renderer_cache(@group,display_path,:skip => @registered_request) do |cache|
      data = {:group => @group, :is_member => is_member, :is_admin => is_admin, :edit_page_url => edit_page_url,
            :registered_request => @registered_request, :suser => @suser, :options => @options,
      :social_unit_type => @options.social_unit_type}

      cache[:output] =  social_unit_group_feature(data)
    end

    render_paragraph :text => result.output
  end
  
  
  def edit_group
    @suser = social_user(myself)
    @options = paragraph_options(:edit_group)

    @group = get_group
    
    @is_admin = @group.is_admin?(myself.id) || editor? if @group

    if !@group && !editor?
      raise  SiteNodeEngine::MissingPageException.new( site_node, language )
    elsif @is_admin
      if params[:group] && request.post?
        handle_image_upload(params[:group],:image_file_id, :location => Configuration.options.user_image_folder)
        @group.attributes = params[:group].slice(*@options.valid_field_parameters)
        if @group.valid?
          @group.save
          @saved = true
          if @options.success_page_id > 0
            return redirect_paragraph @options.success_page_url + "/" + @group.url
          end
        end
      end
    elsif !editor?  &&  @options.invalid_page_url
      return redirect_paragraph @options.invalid_page_url + "/" + @group.url
    end
    @publiction = ContentPublication.find_by_id(@options.content_publication_id)

    render_paragraph :feature => :social_unit_edit_group
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

    @expanded_list = handle_session_parameter(:expand,'0')
    conn_type,conn_id = page_connection
    @options = paragraph_options(:members)

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
    conditions = { }
    if !options.status.blank?
      conditions['status'] = options.status 
    end

    if @group
      @groups = SocialUnit.find(:all,:order => 'name') if @options.show_all
      conditions['social_unit_id'] = @group.id unless @options.show_all
      @pages,@user_members = SocialUnitMember.paginate(page,:conditions => conditions,:per_page => options.per_page,:order => @options.alpha ? 'end_users.last_name, end_users.first_name' : 'social_unit_members.created_at DESC',:joins => :end_user)
      @member_ids = @user_members.map(&:end_user_id)
      @member_profile_entries = UserProfileEntry.fetch_entries(@member_ids,@options.profile_type_id)
      @member_entries= @member_profile_entries.index_by(&:end_user_id)

      @user_profile_type = UserProfileType.find_by_id(@options.profile_type_id)   
      @content_model =  @user_profile_type.content_model if @user_profile_type

      @members = @user_members.map { |m| @member_entries[m.end_user_id] }.compact

      is_admin = @group.is_admin?(myself)
    end

    if params[:download]
      fields = @member_profile_entries[0].content_model.content_model_fields.select { |fld| fld.data_field? && fld.field != 'portrait_expres' }

      file = DomainFile.export_to_csv(@user_members[0].end_user) do |csv|
        csv << [ 'Email', 'First Name','Last Name', 'Gender' ] + fields.map(&:name)
        @user_members.each do |member|
          user = member.end_user
          profile = @member_entries[user.id]
          data = [ user.email,
                   user.first_name,
                   user.last_name,
                   user.gender
                  ]
                   
          if profile
            data += fields.map do |fld|
              profile.content_model_entry.send(fld.field) 
            end
          end
          csv << data
        end
      end
      file = DomainFile.find(file[:domain_file_id])
      output = "#{file.abs_storage_directory}membres.xlsx"

      result = `ssconvert --import-encoding=UTF-8 #{file.filename} #{output}`
      
      return data_paragraph :disposition => 'attachment',  :file => File.exists?(output) ? output : file.filename
      
    end
    
    require_ajax_js

    data = { :admin => is_admin, :group => @group, :groups => @groups, :members => @members, :member_entries => @member_entries, :profile_url => SiteNode.node_path(options.profile_page_id), :pages => @pages, :expanded => @expanded_list, :user_profile_type => @user_profile_type, :content_model => @content_model }
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
      elsif conn_type == :group
        @group = conn_id
      elsif conn_type == :group_id || conn_id.blank?
        if conn_id.blank?
          @group = @suser.social_units(@options.social_unit_type_id)[0]
          if !@group && @options.child_member
            @social_unit_type = SocialUnitType.find_by_id(@options.social_unit_type_id)
            @child_group = @suser.social_units(@social_unit_type.child_type_id)[0]
            
            @group = @child_group.parent if @child_group
          end
        else
          @group = SocialUnit.find_by_url_and_social_unit_type_id(conn_id,@options.social_unit_type_id)
          raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @group
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
