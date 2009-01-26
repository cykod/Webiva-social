

class Social::UnitFeature < ParagraphFeature

  include ContentHelper

  feature :social_unit_location, :default_feature => <<-FEATURE
    <cms:location>
      <cms:groups>
      <cms:group>
          <div class='groups'>
            <cms:location_link>
              <cms:img/><br/>
              <cms:name/>          
            </cms:location_link>
          </div>
        </cms:group>
      </cms:groups>
    </cms:location>
    <cms:no_location>
    
    </cms:no_location>
  FEATURE
  

  def social_unit_location_feature(data)
    webiva_feature(:social_unit_location) do |c|
      c.define_expansion_tag('location') { |tg| data[:location] }
      c.define_value_tag('location:location_name') { |t| data[:location].name }
      c.define_expansion_tag('location:categories') { |t| data[:groups].length > 0 }
      c.define_tag('location:by_category') do |t|
        arr = data[:groups].group_by(&:category)
        order = arr.keys.sort do |a,b|
            if a.nil?
              1
            elsif b.nil? 
              -1
            else
              a <=> b
            end        
        end
        
        c.each_local_value(order.map { |elm| [elm,arr[elm]] },t,'grouping')
      end
      c.define_value_tag('location:by_category:category') { |t| ( t.attr['plural'] ?  t.locals.grouping[0].pluralize : t.locals.grouping[0])  if t.locals.grouping[0]}
        c.define_expansion_tag('location:by_category:groups') { |t| t.locals.grouping[1].length > 0 }
        c.define_expansion_tag('location:groups') { |t| t.locals.grouping ? t.locals.grouping[1] : data[:groups] }
        c.define_tag('location:group') { |t| c.each_local_value(t.locals.grouping ? t.locals.grouping[1] : data[:groups] ,t,'group') }
          c.define_link_tag('group:location') { |tg| data[:group_url].to_s + "/" + tg.locals.group.id.to_s }
          define_group_tags(c,data)
      c.form_for_tag('selector',:select) { |t| LocationSelector.new(data[:selector]) }
          c.field_tag('selector:state',:control => 'select',
                :onchange => "if(this.value!='') new Ajax.Updater('select_location_wrapper','#{ajax_url}?select[state]=' + this.value);", :options =>  [['-State-',nil]] + ContentModel.state_select_options)
          c.field_tag('selector:location',:control => 'select', :options => data[:location_options],
             :onchange => "if(this.value!='') document.location = '#{data[:url]}/' + this.value;") { |t,content| "<span id='select_location_wrapper'>" + content + "</span>" }
          c.submit_tag('update_butt',:default => 'Update')
    end
  end
  
  class LocationSelector < HashModel
    attributes :state => nil, :location => nil
    integer_options :location
  end
  


  feature :social_unit_group, :default_feature => <<-FEATURE
    <cms:group>
      <cms:join>
      <cms:member_link>Join <cms:group/></cms:member_link>
      </cms:join>
      <h1><cms:name/></1>
    </cms:group>
    <cms:no_group>
      Invalid Group
    </cms:no_group>
  
  FEATURE
  
  def social_unit_group_feature(data)
    webiva_feature(:social_unit_group) do |c|
      c.define_expansion_tag('group') { |tg| tg.locals.group = data[:group] }
      c.expansion_tag('group:admin') { |t| data[:is_admin] }
      c.link_tag('group:admin:edit') { |tg| data[:edit_page_url].to_s + "/" + tg.locals.group.id.to_s }
      
      c.expansion_tag('group:not_approved:requested') { |tg| SocialGroupRequest.requested?(myself,tg.locals.group) } 
      c.post_button_tag('group:not_approved:not_requested:button') { |tg| "?request=1" }
      

      c.expansion_tag('group:join') do |t| 
        if t.attr['any']
          !data[:is_member] && data[:suser].group_count(t.locals.group.social_unit_type_id) == 0
        else
          !data[:is_member] 
        end
      end
      
      c.link_tag('group:join:member') do |t|
          path  = SiteNode.node_path(module_options(:social).notification_page_id)
          arg_opts = "act=add_member&group=#{t.locals.group.id}"
          { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }          
      end
      c.define_link_tag("group:invite") do |t|
            msg_opts = module_options(:social)
            path  = SiteNode.node_path(msg_opts.notification_page_id)
            arg_opts = "act=invite_members&group=#{t.locals.group.id}"
            { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
        end      
      if data[:content_model]
        data[:content_model].content_model_fields.each do |fld|
          define_mdl_tag(c,fld,data)
        end
      end
      
      define_group_tags(c,data)
    end
  end
  
  def define_mdl_tag(c,field,data) 
    c.define_value_tag("group:#{field.field}") { |t| display_content_value(data[:entry],field,t.attr) }
  end  
  
  

  feature :social_unit_edit_group, :default_feature => <<-FEATURE
    <cms:group>
      <h1>Edit <cms:name/></h1>
      <cms:form/>
    </cms:group>
  FEATURE
  
  def social_unit_edit_group_feature(data)
    webiva_feature(:social_unit_edit_group) do |c|
      c.define_expansion_tag('group') { |tg| tg.locals.group = data[:group] }
      self.define_group_tags(c,data)
      c.define_tag('group:form') { |t| data[:frm] }      
    end
  end


  feature :social_unit_create_group, :default_feature => <<-FEATURE
    <cms:group>
      <h1>Create a Group</h1>
      <cms:form/>
    </cms:group>
  FEATURE
  
  def social_unit_create_group_feature(data)
    webiva_feature(:social_unit_create_group) do |c|
      c.define_expansion_tag('group') { |tg| tg.locals.group = data[:group] }
      c.define_tag('group:form') { |t| data[:frm] }      
    end
  end
  
  
  
  def define_group_tags(c,data)
    c.value_tag('group_id') { |tg| tg.locals.group.id if tg.locals.group }
    c.image_tag('group:img') { |tg| tg.locals.group.image }
    c.expansion_tag('group:approved') { |tg| tg.locals.group.approved? }
    c.value_tag('group:name') { |tg| tg.locals.group.name }
    c.value_tag('group:parent') { |tg| tg.locals.group.parent ? tg.locals.group.parent.name : nil }
    c.value_tag('group:location') { |tg| tg.locals.group.social_location ? tg.locals.group.social_location.name : nil }
  end
    
  feature :social_unit_members, :default_feature => <<-FEATURE
    <cms:members>
      <cms:member>
      <div class='social_member'>
        <cms:detail_link>
          <cms:img size='thumb'/><br/>
          <cms:name/>
        </cms:detail_link>
        <cms:admin> 
             &nbsp;&nbsp;<cms:remove_link>(Remove <cms:name/>)</cms:remove_link>
        </cms:admin>
      </div>
      </cms:member>
   </cms:members>
    
  
  FEATURE
  
  def social_unit_members_feature(data)
    webiva_feature(:social_unit_members) do |c|
      c.value_tag('group_id') { |t| data[:group].id if data[:group] }
      c.loop_tag('member') { |t| data[:members] }
        c.value_tag('member:name') { |t| t.locals.member.end_user.name  if t.locals.member.end_user}
        c.image_tag('member:img') { |t| t.locals.member.end_user.image  if t.locals.member.end_user }
        c.link_tag('member:detail') { |t| data[:profile_url].to_s + "/" + t.locals.member.end_user_id.to_s   if t.locals.member.end_user }
        c.expansion_tag('member:admin') { |t| data[:admin] }
          c.link_tag('member:admin:remove') do |t|
              msg_opts = module_options(:social)
              @notification_path  ||= SiteNode.node_path(msg_opts.notification_page_id)
              arg_opts = "act=remove_member&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
              { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{@notification_path}','#{arg_opts}');" }          
          end
          c.expansion_tag('member:admin:promote') { |t| t.locals.member.role == 'admin' }
          c.link_tag('member:admin:promote') do |t|
              msg_opts = module_options(:social)
              @notification_path  ||= SiteNode.node_path(msg_opts.notification_page_id)
              if t.locals.member.role != 'admin'
                arg_opts = "act=promote&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
                { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{@notification_path}','#{arg_opts}');" }          
              else
                nil
              end
          end
          c.expansion_tag('member:admin:demote') { |t| t.locals.member.role != 'admin' }
          c.link_tag('member:admin:demote') do |t|
              msg_opts = module_options(:social)
              @notification_path  ||= SiteNode.node_path(msg_opts.notification_page_id)
              if t.locals.member.role == 'admin'
                arg_opts = "act=demote&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
                { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{@notification_path}','#{arg_opts}');" }          
              else
                nil
              end   
          end
        c.pagelist_tag('pages') { |t| data[:pages] }
        c.define_position_tags
    end
  end
  
end
