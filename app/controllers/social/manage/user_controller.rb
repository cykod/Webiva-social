

class Social::Manage::UserController < ModuleController


    component_info "Social" 
    
    def self.members_view_handler_info
    { 
      :name => "Profile Info",
      :controller => '/social/manage/user',
      :action => 'view'
    }
   end  
   
   def view
     @tab = params[:tab]
    @user = EndUser.find(params[:path][0])
    
    @mod_opts = Social::AdminController.module_options()
    
    @content_model = ContentModel.find_by_id(@mod_opts.user_model_id)
    cls = @content_model.content_model 
    @entry = cls.find_by_user_id(@user.id) || cls.new(:user_id => @user.id)
        

    if request.post? && params[:entry]
      if @content_model.update_entry(@entry,params[:entry])
        flash.now[:notice] = 'Updated Profile'
      end
    end
    
    render :partial => 'view'
   end
  
  

end
