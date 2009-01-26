

class Social::Manage::LocationsController < ModuleController


  permit 'social_manage_groups'
  component_info 'Social'
  
   cms_admin_paths "content",
                   "Content" =>   { :controller => '/content' }
  
  
  include ActiveTable::Controller
  
  before_filter :module_opts
  
  def module_opts
    @soc_opts = Social::AdminController.module_options
  end
  
  
  active_table :locations_table, SocialLocation, 
              [ hdr(:icon,'',:size => 16),
                hdr(:string,'name'),
                hdr(:string,'city'),
                hdr(:string,'state'),
                hdr(:string,'zip'),
                hdr(:date,'created_at',:label => 'Created'),
                hdr(:date,'updated_at',:label => 'Updated')
              ]
                

  def display_locations_table(display=true)
    
    active_table_action('location') do |act,lids|
      case act
      when 'delete'
        SocialLocation.destroy(lids)
      end
      DataCache.expire_content("Social","Locations")
    end
    
    @tbl = locations_table_generate params, :order => 'social_locations.name'
  
    render :partial => 'locations_table' if display
  end 

  def index
    cms_page_path [ "Content"],@soc_opts.location_name + " Locations"
  
    display_locations_table(false)
  end


  def edit
    @location = SocialLocation.find_by_id(params[:path][0]) || SocialLocation.new
    
    cms_page_path [ "Content", [ @soc_opts.location_name + " Locations",url_for(:action => 'index')]],@location.id  ? 'Edit Location' : 'Create Location'

    if request.post? && @location.update_attributes(params[:location])
      redirect_to :action => 'index'    
    end    
  end
end
