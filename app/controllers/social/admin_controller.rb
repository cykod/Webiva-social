

class Social::AdminController < ModuleController

  permit 'social_config'

  component_info 'Social', :description => 'Social Networking support', 
                              :access => :private
                              
  # Register a handler feature
  register_permission_category :social, "Social" ,"Permissions related to social networking"
  
  register_permissions :social, [ [ :manage_groups, 'Manage Groups', 'Manage Social Networking Groups' ],
                                  [ :config, 'Configure Social Netwroking', 'Configure Social Networking' ],
                                  [ :ghost, 'Social Networking Ghost', 'Social Networking Ghost Account' ]
                                  ]

  cms_admin_paths "options",
                   "Options" =>   { :controller => '/options' },
                   "Modules" =>  { :controller => '/modules' },
                   "Social Options" => { :action => 'index' }
 
  content_model :social
  
  register_handler :members, :view,  "Social::Manage::UserController"
  
  register_handler :model, :gallery_image, "Social::GalleryExtension", :actions => [ :after_save, :before_destroy ] 
  
  linked_models :end_user, 
                [ :social_user, :social_unit_member, :social_friend, [ :social_friend, :friend_user_id ] ]
  
  protected  
  
  def self.get_social_info
    opts = module_options
    SocialUnitType.find(:all,:order =>'name').map do |ut|
        {:name => "Manage #{ut.name.pluralize}",:url => { :controller => '/social/manage/units', :path => [ ut.id ] }, :permission => 'social_manage_groups' }
    end +
    [
     {:name => "Manage #{opts.location_name} Locations",:url => { :controller => '/social/manage/locations' } ,:permission => 'social_manage' },
    ]
  end
  
 public 
 
  include ActiveTable::Controller
  
  active_table :social_unit_types_table, SocialUnitType, [ :check,:name,"Parents","Children"]
 
  def display_social_unit_types_table(display=true)
    @tbl = social_unit_types_table_generate params, :order => 'name'
    
    render :partial => 'social_unit_types_table' if display
  end
 
  def options
      cms_page_path ['Options','Modules'],'Social Options'
      display_social_unit_types_table(false)
      
  end
  
  def options_edit
    cms_page_path ['Options','Modules','Social Options'], "Options Edit"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && params[:options] && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated social module options".t 
      redirect_to :action => 'options'
      return
    end    
  
  
  end
  
  def unit_type
    @social_unit_type = SocialUnitType.find_by_id(params[:path][0]) || SocialUnitType.new()
    cms_page_path ['Options','Modules','Social Options'], @social_unit_type.id ? "Type Edit" : "Type Create"

    
    if request.post? && params[:social_unit_type] && @social_unit_type.update_attributes(params[:social_unit_type])
      redirect_to :action => :options
      return 
    end
    
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
    attributes :location_name => 'Campus', :user_model_id => nil, :notification_page_id => nil, :role_list => '', :roles => [], :automatic_friend_id => nil, :automatic_wall_message => nil, :automatic_message_id => nil
    
    integer_options :user_model_id, :notification_page_id, :automatic_friend_id,:automatic_message_id
    
    def roles_options
      self.roles.map { |role| [ role.capitalize, role ] }
    end
    
    def validate
      self.roles = self.role_list.split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
    end
  end
      
  
end
