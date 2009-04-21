

class  Social::UserFeature < ParagraphFeature

  include ContentHelper

  feature :social_view_profile, :default_feature => <<-FEATURE 
    <cms:user>
      First Name:<cms:first_name/><br/>
      Last Name:<cms:last_name/><br/>
      <cms:img size='preview'/>
    
      <cms:social_unit>
        <cms:social_unit:parent/>
      </cms:social_unit>
    </cms:user>
  FEATURE
  
  
  def social_view_profile_feature(data)
    webiva_feature(:social_view_profile) do |c|
      c.define_expansion_tag('user') { |tag| data[:user] }
          c.define_expansion_tag('user:private') { |tag| data[:private] }
          
          c.expansion_tag('user:blog') do |t|
            Blog::BlogBlog.find_by_target_type_and_target_id('EndUser',data[:user])
          end
          
          
          c.define_expansion_tag('user:myself') { |tag| data[:myself] }
          define_profile_tags(c,data)
          c.define_tag("user:social_unit") { |tag| c.each_local_value(data[:social_unit_members],tag,'member') }
            c.define_link_tag("user:social_unit:group") { |t| data[:group_page_url].to_s + "/" + t.locals.member.social_unit.id.to_s }
            c.define_value_tag("user:social_unit:name") { |tag| tag.locals.member.social_unit ? tag.locals.member.social_unit.name : nil }
            
            c.define_value_tag("user:social_unit:parent") { |tag| tag.locals.member.social_unit.parent &&  tag.locals.member.social_unit.parent.name ? tag.locals.member.social_unit.parent.name : nil }
          
          c.define_expansion_tag("user:message") { |tag| true }
          c.define_link_tag("user:message") do |tag|
            msg_opts = module_options(:message)
            path  = SiteNode.node_path(msg_opts.inbox_page_id)
            arg_opts = "page=write&recipient_id=end_user_#{data[:user].id}"
            if msg_opts.overlay
              { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
            else
              {:href =>  path + "?" + arg_opts }
            end
          end
          c.define_expansion_tag("user:add_friend") { |tag| !data[:friend] && !data[:outstanding_invite]}
          c.define_expansion_tag("user:friend_request") { |tag| data[:outstanding_invite] }
          c.define_expansion_tag("user:friend") { |tag| data[:friend] }
          c.define_link_tag("user:add_friend") do |tag|
              msg_opts = module_options(:social)
              path  = SiteNode.node_path(msg_opts.notification_page_id)
              arg_opts = "act=add_friend&friend=#{data[:user].id}"
              { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
          end
          c.define_link_tag("user:text") do |tag|
              msg_opts = module_options(:message)
              path  = msg_opts.sms_page_url
              arg_opts = "message[recipient_ids]=end_user_#{data[:user].id}&message[recipients]=#{URI.escape(data[:user].name)}"
              if msg_opts.overlay
                { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
              else
                {:href =>  path + "?" + arg_opts }
              end
          end
          
          c.define_tag('groups') do |t|
           if t.attr['type']
            t.locals.group = [t.attr['type'],data[:groups][t.attr['type'].to_i] ]
            t.expand
           else
            c.each_local_value(data[:groups].to_a,t,'group')
           end
          end
          
          c.define_tag('groups:group') { |t| c.each_local_value(t.locals.group[1],t,'member') }
          c.define_value_tag('groups:group:name') { |t| t.locals.member.social_unit.name }
          c.define_link_tag('groups:group:group') { |t| "#{data[:group_page_url]}/#{t.locals.member.social_unit_id}" }
          
          data[:content_model].content_model_fields.each do |fld|
            define_mdl_tag(c,fld.field,data)
          end
    end 
  end
  
  def define_profile_tags(c,data)
        c.expansion_tag("user:male") { |tag| data[:user].gender == 'm' }
        c.expansion_tag("user:female") { |tag| data[:user].gender == 'f' }
        c.expansion_tag("user:role") { |tag| data[:suser].role == (tag.attr['role'] || 'active') }
        c.define_value_tag("user:user_id") { |tag| data[:user].id }
        c.define_value_tag("user:first_name") { |tag| data[:user].first_name }
        c.define_value_tag("user:last_name") { |tag| data[:user].last_name }
        c.define_value_tag("user:name") { |tag| data[:user].name }
        c.define_value_tag("user:email") { |tag| data[:user].email }
        c.define_image_tag("user:img") { |tag| data[:user].image }
        c.define_image_tag("user:second_img") { |tag| data[:user].second_image }
        c.define_image_tag("user:fallback_img") { |tag| data[:user].second_image || data[:user].image }
  end
  
  def define_mdl_tag(c,field,data) 
    c.define_value_tag("user:#{field}") do |tag| 
        val = data[:entry].send(field); 
        if val.is_a?(Array)
          val
        else
          (tag.attr['format'] ? simple_format(h(val)) : h(val) )  if val 
        end
    
    end
  end
  
  
  feature :social_user_edit_profile, :default_feature => <<-FEATURE
    <cms:user>
      <h1>Edit <cms:name/></h1>
      <cms:form/>
    </cms:user>
  FEATURE
  
  def social_user_edit_profile_feature(data)
    webiva_feature(:social_user_edit_profile) do |c|
      
      c.define_expansion_tag('user') { |tg| tg.locals.user = data[:user] }
      define_profile_tags(c,data)
      c.form_for_tag('user:form','entry', :html => { :enctype => 'multipart/form-data' }) { |t| data[:entry] }
      c.define_tag('user:account') { |t| data[:frm] }     
      
    data[:publication].content_publication_fields.each do |fld|
        tag_name = %w(belongs_to document image).include?(fld.content_model_field.field_type) ? fld.content_model_field.field_options['relation_name'] :      fld.content_model_field.field
        if fld.field_type=='input'
          c.define_tag "user:form:#{tag_name}" do |tag|
            opts = { :label => fld.label,:size => 40, :control => fld.data[:control] }
            opts[:size] = tag.attr['size'] if tag.attr['size']
            content_field(tag.locals.form,fld.content_model_field,opts)
          end
          
          
          c.define_tag "user:form:#{tag_name}_error" do |tag|
            val = nil        
            errs = data[:entry].errors.on(fld.content_model_field.field)
            if errs.is_a?(Array)
              errs = errs.uniq
              val = errs.collect { |msg| 
                fld.label + " " + msg.t + "<br/>"
              }.join("\n")
            elsif errs
              val = fld.label + " " + errs.t
            end
            
            if tag.single?
              val
            elsif val 
              tag.locals.value = val
              tag.expand
            else 
              nil
            end
          end
          
          c.define_tag "user:form:#{tag_name}_error:value" do |tag|
            tag.locals.value
          end
        elsif fld.field_type == 'value'
          c.define_tag "user:form:#{tag_name}" do |tag|
            tag.locals.value = display_content_value(data[:entry],fld.content_model_field,tag.attr)
            tag.single? ? tag.locals.value : (tag.locals.value.blank? ? nil : tag.expand)
          end
        end
        
    
      end      
       
    end
  end  
  
  feature :social_friends, :default_feature => <<-FEATURE
    <cms:group>
      <h1><cms:group_name/></h1>
      <cms:friends>
        <cms:friend>
          <div class='social_friend'>
            <cms:detail_link>
              <cms:img/><br/
              <cms:name/>
            </cms:detail_link>
          </div>
        </cms:friend>
      </cms:friends>
    </cms:group>
    
  
  FEATURE
  
  def social_friends_feature(data)
    webiva_feature(:social_friends) do |c|
      c.define_tag('user_id') { |t| data[:user].id }
      c.expansion_tag('user') { |t| data[:user] }
      c.define_tag('user:name') { |t| data[:user].name }
      c.define_tag('user:first_name') { |t| data[:user].first_name }
      c.define_tag('user:last_name') { |t| data[:user].last_name }
      c.define_tag('group') { |tg| c.each_local_value(data[:friends],tg,"group") }
        c.value_tag('group:group_name') { |tg| tg.locals.group[0] ? tg.locals.group[0].name : nil }
        c.loop_tag('group:friend')  { |tg| tg.locals.group[1] }
          c.image_tag('group:friend:img') { |tg| tg.locals.friend.image }
          c.value_tag('group:friend:name') { |tg| tg.locals.friend.name }
          c.link_tag('group:friend:detail') { |tg| data[:profile_url].to_s + "/" + tg.locals.friend.id.to_s }
          c.post_button_tag('group:friend:remove') { |tg| data[:user].id == myself.id ? '?remove_friend=' + tg.locals.friend.id.to_s : nil }
    end
  end
  
  feature :social_user_friend_groups, :default_feature => <<-FEATURE
    <cms:groups>
    <cms:group>
      <cms:group_link><cms:name/> (<cms:count/>)</cms:group_link><br/>
    </cms:group>
    </cms:groups>
  FEATURE
  
  def social_user_friend_groups_feature(data)
    webiva_feature(:social_user_friend_groups) do |c|
      c.define_tag('user_id') { |t| data[:user].id }
      c.loop_tag('group') { |t|  data[:groups] }
      c.define_tag('group:name') { |t| t.locals.group[0].name }
      c.define_tag('group:count') { |t| t.locals.group[1] }
      c.define_link_tag('group:group') { |t| "#{data[:friends_page_url]}/#{data[:user].id}?group_id=#{t.locals.group[0].id}" }
    end
  
  end
  
  
  feature :social_user_search, :default_feature => <<-FEATURE
 <cms:user_search> 
   Search For: <cms:name/> <cms:update_butt/> <br/>
   <cms:where/> 
 </cms:user_search>
 <cms:searched>
   <cms:results>
    <cms:result>
       <cms:profile_link><cms:name/></cms:profile_link>
    </cms:result>
   </cms:results>
   <cms:no_results>
    No Results
   </cms:no_results>
</cms:searched>
<cms:not_searched>
  Enter User information and click search
</cms:not_searched>
  FEATURE
  
  def social_user_search_feature(data)
    webiva_feature(:social_user_search) do |c|
      c.form_for_tag('user_search',:search) { |t| UserSearch.new(params[:search]) }
          c.field_tag('user_search:name')
          c.field_tag('user_search:where',:control => :radio_buttons, :options => [ ['All Groups','all'],['Parent Groups','national'],['Member Groups','local']], :separator => 'XXX' )
          c.submit_tag('update_butt',:default => 'Search')    
      c.define_expansion_tag('searched') { |t| data[:results] ? true : false }
      c.loop_tag('result') { |t| data[:results] }
        c.define_value_tag('result:name') { |t| t.locals.result[:user].name }
        c.define_image_tag('result:img') { |t| t.locals.result[:user].image }
        c.define_image_tag("result:second_img") { |t| t.locals.result[:user].second_image }
        c.define_image_tag("result:fallback_img") { |t| t.locals.result[:user].second_image || t.locals.result[:user].image }
        
        c.define_value_tag('result:groups') { |t| t.locals.result[:groups].map { |group| group.social_unit.name }.join(", ") }
        c.define_link_tag('result:profile') { |t| "#{data[:profile_page]}/#{t.locals.result[:user].id}" }
    end
  end
  
 class UserSearch < HashModel
  attributes :name => nil, :where => 'all'
 end
  

end
