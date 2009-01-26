

class Social::MessageRenderer < Social::SocialRenderer

  features '/social/message_feature'

  paragraph :wall, :ajax => true
  paragraph :notify, :ajax => true

  def wall
    @options = paragraph_options(:wall)
    @mod_opts = module_options(:social)
    
    
    if ajax? && params[:target_hash]
      target_hash = params[:target_hash]
      target_class,target_id = session['user_wall_target_' + params[:target_hash]]
      
      begin
        @target = target_class.constantize.find(target_id)
      rescue Exception => e
        return
      end
    end
      
   if ajax? && params[:remove_message] && params[:remove_message][paragraph.id.to_s]
      entry= SocialWallEntry.find_by_id(params[:remove_message][paragraph.id.to_s],:conditions => { :target_id => @target.id, :target_type => @target.class.to_s })
      if entry && (entry.end_user_id = myself.id || can_edit)
        entry.destroy
        redirect_paragraph paragraph_page_url
        return
      end
    else
      if !@target
        connection_type,conn_id = page_connection
        if connection_type == :wall_target
          @target = conn_id
        else 
          @target = nil
        end
      end
      
      can_edit = @target ? @target.is_admin?(myself) : false
      
      if @target
        target_hash = DomainModel.generate_hash
        session['user_wall_target_' + target_hash] = [ @target.class.to_s, @target.id  ]
      end
      
      post = SocialWallEntry.new
      
      if @target && request.post? && params[:wall]
        entry = SocialWallEntry.create(:message => params[:wall][:message], :target => @target, :end_user_id => myself.id)
        if !ajax? && entry
          redirect_paragraph :page
          return
        end 
      end
      
      cur_page = params[:wall_page].to_i
      cur_page = 1 if cur_page < 1
      if @target
        pages,wall_entries = SocialWallEntry.paginate(cur_page,:conditions => ["target_type =? AND target_id=?",@target.class.to_s,@target.id],:order => 'created_at DESC',:per_page => 20)
        more = (cur_page < pages[:pages])
      end
      
      data = { :target => @target, :paragraph => paragraph, :entries => wall_entries, :post => post, :can_edit => can_edit, :target_hash => target_hash, :ajax => ajax?, :more => more  }
      
      render_paragraph :text =>  social_message_wall_feature(data)
    end
  end
  
  def notify
  
    if ajax? && params[:page].to_s == 'autocomplete'
      display_autocomplete
      return
    end
    
    case params[:act]
    when 'add_friend': add_friend
    when 'remove_member': remove_member
    when 'add_member': add_member
    when 'invite_members': invite_members
    when 'promote': promote
    when 'demote': demote
    when 'job_inquiry': job_inquiry
    else
      render_paragraph :text => 'Invalid Notification'
    end
  end

  private   
  
 def display_autocomplete
    
    mod_opts = module_options(:message)
    if params[:message_recipients]
      @users = []
      name = params[:message_recipients].split(" ").collect { |elm| elm.strip }.find_all { |elm| !elm.blank? }
      full_name = name.join(" ")
      if @users.length == 0  && name.length > 0
        if(name.length == 1)
          name = "%" + name[0].downcase + "%"
          @conditions = [ 'last_name LIKE ? OR first_name LIKE ?',name,name ]
        else
          if name[0][-1..-1] == "," # Handle rettig, pascal
            name = [name[1],name[0][0..-2]]
          end
          @conditions = [ 'first_name LIKE ? AND last_name LIKE ?',"%" + name[0].downcase + "%","%" + name[1].downcase + "%" ]
        end
        
        if mod_opts.use_friends 
          @suser = SocialUser.user(myself) 
          @users = SocialUnit.find(:all,:conditions => ['social_units.name LIKE ? AND social_unit_members.end_user_id=?', "%#{full_name}%",myself.id],:group => 'social_units.id', :joins => 'LEFT JOIN social_unit_members ON (social_unit_members.social_unit_id = social_units.id)' )

          @conditions[0] += " AND social_friends.end_user_id= ?"
          @conditions << myself.id
          @users += SocialFriend.find(:all,:group => 'end_users.id', :conditions => @conditions,:joins => [ :friend_user ]).collect { |usr| usr.friend_user }
          
          
        else
          @users = EndUser.find(:all,:conditions => @conditions, :order => 'last_name, first_name')
        end
      end      
          
    end

    @view_data = { :users => @users }
    render_paragraph :partial => '/message/mailbox/display_autocomplete', :locals => @view_data  
  end  
  
  
  def add_friend
    @user = EndUser.find_by_id(params[:friend])
    @confirmed = params[:confirm] ? true : false
    @view_data = { :user => @user, :renderer => self, :confirmed => @confirmed, :ajax => ajax? }
    
    if @confirmed
       msg = MessageTemplate.create_message('friend_request',myself)
       msg.send_notification(@user,'/social/friend_notification',:from_user_id => myself.id)
       

    end
    
    render_paragraph :partial => '/social/message/add_friend', :locals => @view_data
  end
  
  def remove_member 
    @group = SocialUnit.find_by_id(params[:group])
    if @group.is_admin?(myself) && @member = @group.social_unit_members.find_by_end_user_id(params[:user])
      
      @confirmed = params[:confirm] ? true : false
      if @confirmed
        @member.destroy
        msg = MessageTemplate.create_message('member_removed',nil, { :group_name => @group.name })
        msg.send_notification(@member.end_user)
      end
      
      @view_data = { :member => @member, :user => @member.end_user, :group => @group, :renderer => self, :confirmed => @confirmed , :ajax => ajax?}
      render_paragraph :partial => '/social/message/remove_member', :locals => @view_data
    else
      render_paragraph :text => 'Invalid Notification'
    end 
  end
  
  def add_member
    @group = SocialUnit.find_by_id(params[:group])
    if @group && myself.id && !@group.social_unit_members.find_by_end_user_id(myself.id)
      @confirmed = params[:confirm] ? true : false
      if @confirmed
        
        msg = MessageTemplate.create_message('member_request',nil, { :user => myself, :group_name => @group.name })
        msg.send_notification(@group.administrators,'/social/member_notification', :group_id => @group.id, :from_user_id => myself.id)
      end
      
      @view_data = { :group => @group, :renderer => self, :confirmed => @confirmed , :ajax => ajax?}
      render_paragraph :partial => '/social/message/add_member', :locals => @view_data
    else
      render_paragraph :text => 'Invalid Notification'
    end 
  end
  
  def invite_members
    @group = SocialUnit.find_by_id(params[:group])
    if @group && @group.is_admin?(myself)
      @confirmed = params[:confirm] ? true : false
      
      message = MessageMessage.new()
      
      if request.post? && params[:message] 
        message.attributes = params[:message]
        message.from_user = myself
        message.subject = 'dummy'
        message.message = 'dummy' if message.message.blank?
        valid_users = []
        
        if !params[:partial]
          message.valid?
          message.recipient_users.each do |usr|
           valid_users << usr
          end      
        end
        
        if @confirmed && message.errors.length == 0
          message.message = '' if message.message.blank?
          valid_users.each do |user|
            msg = MessageTemplate.create_message('group_invite',myself, { :user => myself, :group_name => @group.name, :message => message.message })
            msg.send_notification(user,'/social/member_invite', :group_id => @group.id, :from_user_id => myself.id)
          end
          
        end
      end
      
      @suser = SocialUser.user(myself) 

      targets = @suser.social_units + EndUser.find(:all,:conditions => { :id => SocialFriend.friends_cache(myself.id) },:order => 'last_name,first_name', :include => :domain_file )
    
      
      @view_data = { :message => message, :group => @group, :renderer => self, :confirmed => @confirmed , :ajax => ajax?, :friends => targets}
      render_paragraph :partial => '/social/message/invite_members', :locals => @view_data
    else
      render_paragraph :text => "Invalid Notification"
    end 
  end
  
  def promote
    @group = SocialUnit.find_by_id(params[:group])
    if @group.is_admin?(myself) && @member = @group.social_unit_members.find_by_end_user_id_and_role(params[:user],'member')
      @confirmed = params[:confirm] ? true : false
      if @confirmed
        @group.add_member(@member.end_user,nil,'admin')
        msg = MessageTemplate.create_message('member_promoted',nil, { :group_name => @group.name })
        msg.send_notification(@member.end_user)
      end
      
      @view_data = { :member => @member, :user => @member.end_user, :group => @group, :renderer => self, :confirmed => @confirmed , :ajax => ajax?}
      render_paragraph :partial => '/social/message/promote_member', :locals => @view_data
    else
      render_paragraph :text => "#{@member.end_user.name} is already an Administrator"
    end 
  end
  
  def demote
    @group = SocialUnit.find_by_id(params[:group])
    if @group.is_admin?(myself) && @member = @group.social_unit_members.find_by_end_user_id(params[:user],'admin')
      @confirmed = params[:confirm] ? true : false
      if @confirmed
        @group.add_member(@member.end_user,nil,'member')
        msg = MessageTemplate.create_message('member_demoted',nil, { :group_name => @group.name })
        msg.send_notification(@member.end_user)
      end
      
      @view_data = { :member => @member, :user => @member.end_user, :group => @group, :renderer => self, :confirmed => @confirmed, :ajax => ajax? }
      render_paragraph :partial => '/social/message/demote_member', :locals => @view_data
    else
      render_paragraph :text => "#{@member.end_user.name} is already an Administrator"
    end 
  end
  
  
  def job_inquiry
    @posting = JobsPosting.find_by_id(params[:posting_id])
    if @posting
      resume = JobsResume.user_resume(myself)
      @confirmed = params[:confirm] ? true : false
      
      if @confirmed
        if resume && resume.resume_file && params[:message][:resume] && !params[:message][:resume][0].blank?
          msg = MessageTemplate.create_message('job_inquiry_resume',myself, { :job => @posting.title, :resume => resume.resume_file.url , :message => simple_format(h(params[:message][:message])) })
        else
          msg = MessageTemplate.create_message('job_inquiry',myself, { :job => @posting.title,  :message => simple_format(h(params[:message][:message])) })
        end
        msg.send_notification(@posting.end_user)
      end
      @view_data = { :posting => @posting,:message => HashModel.new({}), :resume => resume, :group => @group, :renderer => self, :confirmed => @confirmed, :ajax => ajax? }
      render_paragraph :partial => '/social/message/job_inquiry', :locals => @view_data
    else
      render_paragraph :text => "Invalid Job Posting"
    end
      
  end

end
