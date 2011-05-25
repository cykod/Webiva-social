

class  Social::UserFeature < ParagraphFeature

  include Social::UnitFeature::SocialUnitTags
 
  feature :social_view_profile, :default_feature => <<-FEATURE 
    <cms:user>
      First Name:<cms:first_name/><br/>
      Last Name:<cms:last_name/><br/>
      <cms:img size='preview'/>
    
      <cms:groups>
      Member of: <cms:group><cms:canonical_link><cms:name/></cms:canonical_link><cms:not_last>, </cms:not_last></cms:group>
      </cms:groups>
    </cms:user>
  FEATURE
  
  
  def social_view_profile_feature(data)
    webiva_custom_feature(:social_view_profile) do |c|
      c.define_expansion_tag('user') { |t| t.locals.user = data[:user] }
      c.user_details_tags('user') { |t| t.locals.user }

      c.h_tag('user:url') { |t| data[:user_profile].url }
      c.expansion_tag('user:profile') { |t| t.locals.entry = data[:user_profile].content_model_entry if data[:content_model] }
      c.define_expansion_tag('user:private') { |tag| data[:private] }
          
      c.expansion_tag('user:blog') do |t|
        Blog::BlogBlog.find_by_target_type_and_target_id('EndUser',data[:user])
      end

      c.expansion_tag('logged_in') { |t| myself.id }

      c.content_model_fields_value_tags('user:profile', data[:user_profile].user_profile_type.display_content_model_fields) if data[:user_profile] && data[:content_model]

      c.define_expansion_tag('user:myself') { |t| t.locals.user == myself }

      c.expansion_tag('user:main_group') { |t| t.locals.group =  data[:primary_group].social_unit if data[:primary_group] }
      define_group_tags(c,'user:main_group')

      c.loop_tag('user:group_type') { |t| data[:groups_types].to_a }
      c.h_tag('user:group_type:group') { |t| t.locals.group_type[0][0].social_unit_type.name }
      c.loop_tag('user:group_type:group') { |t| t.locals.group_type[0].map(&:social_unit) }
      define_group_tags(c,'user:group_type:group')

      c.loop_tag('user:group') { |t| data[:groups].map(&:social_unit) }
      define_group_tags(c,'user:group') 

      c.expansion_tag('is_group_admin') { |t| data[:is_group_admin] }


      c.define_link_tag("user:message") do |tag|
        msg_opts = module_options(:message)
        path  = msg_opts.write_page_url
        if !path.blank?
          arg_opts = "cms_partial_page=1&page=write&recipient_id=end_user_#{data[:user].id}"
          if msg_opts.overlay
            { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
          else
            {:href =>  path + "?" + arg_opts }
          end
        end
      end
      c.define_expansion_tag("user:add_friend") { |tag| !data[:is_myself] && !data[:is_friend] && !data[:outstanding_invite]}
      c.define_expansion_tag("user:friend_request") { |tag| data[:outstanding_invite] }
      c.define_expansion_tag("user:friend") { |tag| data[:friend] }
      c.define_link_tag("user:add_friend") do |tag|
        if !data[:is_myself] && !data[:is_friend] && !data[:outstanding_invite]
          msg_opts = module_options(:social)
          path  = SiteNode.node_path(msg_opts.notification_page_id)
          arg_opts = "cms_partial_page=1&act=add_friend&friend=#{data[:user].id}"
          { :href => 'javascript:void(0);', :onclick => "SCMS.remoteOverlay('#{path}','#{arg_opts}');" }
        end
      end
    end 
  end
  
   
  feature :social_friends, :default_feature => <<-FEATURE
    <cms:user>
    <h1><cms:first_name/>'s Friends</h1>
    <cms:friend>
    <div class='social_friend'>
        <cms:detail_link><cms:img/></cms:detail_link>
        <cms:detail_link><cms:name/></cms:detail_link>
        <cms:remove/>
    </div>
    </cms:friend>
    </cms:user>
  FEATURE
  
  def social_friends_feature(data)
    webiva_feature(:social_friends) do |c|
      c.value_tag('user_id') { |t| data[:user].id }
      c.expansion_tag('user') { |t| data[:user] }
 
      c.h_tag('user:name') { |t| data[:user].name }
      c.h_tag('user:first_name') { |t| data[:user].first_name }
      c.h_tag('user:last_name') { |t| data[:user].last_name }

      c.loop_tag('friend') { |t| data[:friends] }
      c.image_tag('friend:img',nil,nil,:size => 'thumb') { |tg| tg.locals.friend.end_user.image }

      
      c.define_user_details_tags("friend", :local => 'friend' )

      c.link_tag('friend:detail') { |tg| data[:profile_url].to_s + "/" + tg.locals.friend.url.to_s }
      c.post_button_tag('friend:remove',:button => 'Remove') { |tg| data[:is_myself] ?  '?remove_friend=' + tg.locals.friend.end_user_id.to_s : nil }
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
