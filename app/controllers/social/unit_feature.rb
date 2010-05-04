

class Social::UnitFeature < ParagraphFeature

  feature :social_unit_location, :default_feature => <<-FEATURE
      <cms:groups>
      <ul class='social_groups'>
      <cms:group>
        <li><cms:img size='thumb' align='left'/> <cms:link><cms:name/></cms:link>
        </li>     
      </cms:group>
      </ul>
      </cms:groups>
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

        c.loop_tag('group') { |t| t.locals.grouping ? t.locals.grouping[1] : data[:groups] }
          c.define_link_tag('group:') { |tg| data[:options].group_page_url.to_s + "/" + tg.locals.group.url.to_s }
          define_full_group_tags(c,'group',data)
      c.form_for_tag('selector',:select) { |t| LocationSelector.new(data[:selector]) }
          c.field_tag('selector:state',:control => 'select',
                :onchange => "if(this.value!='') new Ajax.Updater('select_location_wrapper','#{ajax_url}?select[state]=' + this.value);", :options =>  [['-State-',nil]] + ContentModel.state_select_options(true))
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
      <h1><cms:name/></h1>
    </cms:group>
    <cms:no_group>
      Invalid Group
    </cms:no_group>
  
  FEATURE
  
  def social_unit_group_feature(data)
    webiva_custom_feature(:social_unit_group) do |c|
      c.define_expansion_tag('group') { |tg| tg.locals.group = data[:group] }
      c.expansion_tag('group:admin') { |t| data[:is_admin] }
      c.link_tag('group:admin:edit') { |tg| data[:edit_page_url].to_s + "/" + tg.locals.group.url.to_s }

      c.link_tag('group:') { |tg| data[:options].base_page_url.to_s + "/" + tg.locals.group.url.to_s }
      c.link_tag('group:sub') { |tg| data[:options].base_page_url.to_s + "/" + tg.attr['page'].to_s + '/'  + tg.locals.group.url.to_s }
      c.expansion_tag('group:join') do |t| 
        if !myself.id
          nil
        elsif t.attr['any']
          !data[:is_member] && data[:suser].group_count(t.locals.group.social_unit_type_id) == 0
        else
          !data[:is_member] 
        end
      end
      
      c.link_tag('group:join:member') do |t|
          path  = SiteNode.node_path(module_options(:social).notification_page_id)
          arg_opts = "cms_partial_page=1&act=add_member&group=#{t.locals.group.id}"
          { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }          
      end
      c.define_link_tag("group:invite") do |t|
            msg_opts = module_options(:social)
            path  = SiteNode.node_path(msg_opts.notification_page_id)
            arg_opts = "cms_partial_page=1&act=invite_members&group=#{t.locals.group.id}"
            { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
      end      
      
      c.expansion_tag('group:blog') do |t|
        Blog::BlogBlog.find_by_target_type_and_target_id('SocialUnit',t.locals.group.id)
      end
      
      define_full_group_tags(c,"group",data)
    end
  end
  

  feature :social_unit_edit_group, :default_feature => <<-FEATURE
    <cms:group>
      <h1>Edit <cms:name/></h1>
      <ul class='webiva_form social_group_form'>
       <cms:field>
         <cms:item>
           <cms:label/><cms:control/>
         </cms:item>
       </cms:field/>
      <cms:details>
        <cms:field>
          <cms:item/>
        </cms:field>
      </cms:details>
       <cms:submit/>
      </ul>
    </cms:group>
  FEATURE
  
  def social_unit_edit_group_feature(data)
    webiva_custom_feature(:social_unit_edit_group) do |c|
      c.form_for_tag('group','group', :html => { :enctype => 'multipart/form-data' }) { |tg| data[:is_admin] ? (tg.locals.group = data[:group]) : nil } 
      self.define_group_tags(c,'group',data)
      c.form_fields_tag('group:field',data[:options].ordered_field_list) 

      c.fields_for_tag('group:details','group[entry]') do |tg| 
        data[:options].publication ? tg.locals.group.model_entry : nil
      end
      c.publication_field_tags('group:details',data[:options].publication) if data[:options].publication
      c.button_tag('group:submit')
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
  
  
  module SocialUnitTags
  
    def define_group_tags(c,base,opts = {})
      local = opts[:local] || "group"
      c.value_tag("#{base}:group_id") { |tg| tg.locals.send(local).id if tg.locals.send(local) }
      c.image_tag("#{base}:img") { |tg| tg.locals.send(local).image }
      c.expansion_tag("#{base}:approved") { |tg| tg.locals.send(local).approved? }
      c.value_tag("#{base}:name") { |tg| tg.locals.send(local).name }
      c.value_tag("#{base}:parent") { |tg| tg.locals.send(local).parent ? tg.locals.send(local).parent.name : nil }
      c.link_tag("#{base}:content") { |tg| tg.locals.send(local).content_node.link } 
      c.value_tag("#{base}:location") { |tg| tg.locals.send(local).social_location ? tg.locals.send(local).social_location.name : nil }
    end

    def define_full_group_tags(c,base,data,opts = {})
      local = opts[:local] || "group"
      define_group_tags(c,base,opts)

      if data[:social_unit_type]
        c.expansion_tag(base + ":details") { |t| t.locals.entry = t.locals.send(local).model_entry }
        c.content_model_fields_value_tags('group:details', data[:social_unit_type].display_content_model_fields) if data[:social_unit_type].content_model
      end
    end
  end

  include SocialUnitTags
    
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
        c.define_user_details_tags("member", :local => 'member' )
        c.image_tag('member:img') { |t| t.locals.member.end_user.image  if t.locals.member.end_user }
        c.link_tag('member:detail') { |t| data[:profile_url].to_s + "/" + t.locals.member.url.to_s   if t.locals.member.end_user }
        c.expansion_tag('member:admin') { |t| data[:admin] }
          c.link_tag('member:admin:remove') do |t|
              msg_opts = module_options(:social)
              @notification_path  ||= SiteNode.node_path(msg_opts.notification_page_id)
              arg_opts = "cms_partial_page=1&act=remove_member&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
              { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{@notification_path}','#{arg_opts}');" }          
          end
          c.expansion_tag('member:admin:promote') { |t| t.locals.member.role == 'admin' }
          c.link_tag('member:admin:promote') do |t|
              msg_opts = module_options(:social)
              @notification_path  ||= SiteNode.node_path(msg_opts.notification_page_id)
              if t.locals.member.role != 'admin'
                arg_opts = "cms_partial_page=1&act=promote&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
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
                arg_opts = "cms_partial_page=1&act=demote&group=#{data[:group].id}&user=#{t.locals.member.end_user_id}"
                { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{@notification_path}','#{arg_opts}');" }          
              else
                nil
              end   
          end
        c.pagelist_tag('pages') { |t| data[:pages] }
        c.define_position_tags
    end
  end
  
  feature :social_unit_member_location, :default_feature => <<-FEATURE
    <cms:groups>
    <cms:group>
      <cms:group_link><cms:location/> (<cms:count/>)</cms:group_link><br/>
    </cms:group>
    </cms:groups>
  FEATURE
  
  def social_unit_member_location_feature(data)
    webiva_feature(:social_unit_member_location) do |c|
      c.define_tag('user_id') { |t| data[:user].id }
      c.loop_tag('group') { |t|  data[:groups] }
      c.value_tag('group:name') { |t| t.locals.group[0].name }
      c.value_tag('group:location') { |t| t.locals.group[1] ? t.locals.group[1].name : nil   }
      c.value_tag('group:city') { |t| t.locals.group[1] ? t.locals.group[1].city : nil   }
      c.value_tag('group:state') { |t| t.locals.group[1] ? t.locals.group[1].state : nil   }
      c.value_tag('group:count') { |t| t.locals.group[2]  }
      c.link_tag('group:canonical') { |t| "#{data[:group_page_url]}/#{t.locals.group[0].id}" }

    end
  
  end  
  
end
