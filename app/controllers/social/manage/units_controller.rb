

class Social::Manage::UnitsController < ModuleController


  permit 'social_manage_groups'
  component_info 'Social'
  
   cms_admin_paths "content",
                   "Content" =>   { :controller => '/content' }
  
  
  include ActiveTable::Controller
  
  before_filter :module_opts
  
  def module_opts
    @soc_opts = Social::AdminController.module_options
  end
  
  

  def display_units_table(display=true)
    @social_unit_type = SocialUnitType.find(params[:path][0])
  
   columns = [  self.class.hdr(:icon,'',:size => 16),
               self.class.hdr(:icon,'',:size => 16),
                self.class.hdr(:string,'social_units.name'),
                self.class.hdr(:string,'social_locations.name', :label => 'Location'),
                self.class.hdr(:string,'category', :label => 'Type')
             ] +
              (@social_unit_type.has_parents? ? [  self.class.hdr(:order,'parent_id',:label => @social_unit_type.parent_name) ] : []) +
              [  self.class.hdr(:date,'created_at',:label => 'Created'),
                self.class.hdr(:date,'updated_at',:label => 'Updated'),
                self.class.hdr(:boolean,'social_units.approved'),
                self.class.hdr(:string,'lead_source',:label => 'Src.')
              ] 
                

    
    active_table_action('unit') do |act,uids|
      case act
      when 'delete'
        SocialUnit.destroy(uids)
      when 'approve':
        SocialUnit.find(uids).each { |unit| unit.update_attribute(:approved,1) }
      when 'unapprove':
        SocialUnit.find(uids).each { |unit| unit.update_attribute(:approved,0) }
      end
      DataCache.expire_content("Social","Units")
    end
    
    
    
    @tbl =  active_table_generate('units_table',SocialUnit,columns,{},params,{  :order => 'social_units.name', :conditions => [ 'social_unit_type_id=?',@social_unit_type.id], :joins => " LEFT JOIN social_locations ON (social_locations.id = social_units.social_location_id)" })  

  
    render :partial => 'units_table' if display
  end 

  def index
    display_units_table(false)
    cms_page_path [ "Content"],  "Manage #{@social_unit_type.name.pluralize}"
  
  end
  
  active_table :unit_members_table, SocialUnitMember, [ :check, :end_user, :role,:created_at,:updated_at  ]
  
  def display_unit_members_table(display=true)
    @social_unit_type = SocialUnitType.find(params[:path][0]) unless @social_unit_type
    @unit = SocialUnit.find(params[:path][1]) unless @unit
    
    active_table_action('member') do |act,mids|
      case act
      when 'remove':  EndUser.find(mids).each { |usr| @unit.remove_member(usr) }
      when 'admin': EndUser.find(mids).each { |usr| @unit.add_member(usr,nil,'admin') }
      when 'member': EndUser.find(mids).each { |usr| @unit.add_member(usr,nil,'member') }
      end
      DataCache.expire_content("Social","Units")
    end

    @tbl =  unit_members_table_generate params,:order => 'updated_at DESC',
          :joins => [ :end_user ],:conditions => ['social_unit_id = ?',@unit.id ]
  
    render :partial => 'unit_members_table' if display
  end
  
  active_table :unit_wall_table, SocialWallEntry, [ :check, :end_user, :created_at,:message ]
  
  def display_unit_wall_table(display=true)
    @social_unit_type = SocialUnitType.find(params[:path][0]) unless @social_unit_type
    @unit = SocialUnit.find(params[:path][1]) unless @unit
    
    active_table_action('wall_entry') do |act,wids|
      case act
      when 'delete':  SocialWallEntry.destroy(wids)
      end
      DataCache.expire_content("Social","Units")
    end

    @wall_tbl =  unit_wall_table_generate params,:order => 'updated_at DESC',
          :joins => [ :end_user ],:conditions => ['target_type = ? AND target_id=?',@unit.class.to_s,@unit.id ]
  
    render :partial => 'unit_wall_table' if display
  end
  
  def view
    display_unit_members_table(false)
    display_unit_wall_table(false)
  
    cms_page_path [ "Content", 
                  [ "Manage %s",url_for(:action => 'index', :path => [ @social_unit_type.id ]),@social_unit_type.name.pluralize]],
                  "View #{@social_unit_type.name}: #{@unit.name}" + (@unit.social_location ? "- #{@unit.social_location.name}" : "")
  end
  
  def add_member
    @social_unit_type = SocialUnitType.find(params[:path][0]) unless @social_unit_type
    @unit = SocialUnit.find(params[:path][1]) unless @unit
    
    usr = EndUser.find_by_id(params[:user_id])
    @unit.add_member_with_notification(usr,'active',params[:admin]=='true' ? 'admin' : 'member') if usr

    display_unit_members_table
  end
  
  def edit
    @social_unit_type = SocialUnitType.find(params[:path][0])
  
    @unit = SocialUnit.find_by_id(params[:path][1]) || SocialUnit.new(:social_unit_type_id => @social_unit_type.id)
    
    cms_page_path [ "Content", 
                  [ "Manage %s",url_for(:action => 'index', :path => [ @social_unit_type.id ]),@social_unit_type.name.pluralize]],
                  @unit.id  ? 'Edit ' +  @social_unit_type.name : 'Create ' +  @social_unit_type.name

    if request.post? && params[:unit] 
      if @unit.update_attributes(params[:unit])
        redirect_to :action => 'index',:path => [@social_unit_type.id]
      end
    end    
    
    if @social_unit_type.has_parents?
      @parents = [["--No #{@social_unit_type.parent_name}--",nil]] + SocialUnit.find_select_options(:all,:conditions => { :social_unit_type_id => @social_unit_type.parent_type_id },:order => 'name')
    end
    if @social_unit_type.has_location?
      @locations = [["--No #{@soc_opts.location_name}--",nil]] +SocialLocation.find_select_options(:all,:order => 'name')
    end
  end

end
