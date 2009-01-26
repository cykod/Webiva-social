class  Social::MessageFeature < ParagraphFeature
  include ActionView::Helpers::UrlHelper
  
  feature :social_message_wall, :default_feature => <<-FEATURE
    <cms:wall>
      <div class='wall'>
      <cms:form>
        <cms:post prefill='Enter your comments..'/>
        <cms:button>Post</cms:button>
      </cms:form>
      <cms:entries>
        <cms:entry>
          <div class='wallimg'>
              <cms:img/>
          </div>
          <div class='walltxt'>
            <cms:name/> wrote:<br/>
            <cms:date/><br/>
            <cms:message/>
          </div>
        </cms:entry>
      </cms:entries>
      </div>
    </cms:wall>
  FEATURE


  def social_message_wall_feature(data)
    feature = get_feature(:social_message_wall)
    if data[:entry] # if it's a partial - only render the entry
      if feature.body_html =~ /\<cms\:entry\>(.*)\<\/cms\:entry\>/m
        feature = $1 
      end
      partial_feature = true
    elsif data[:ajax]
      if feature.body_html =~ /\<cms\:entries\>(.*)\<\/cms\:entries\>/im
        feature.body_html = $1 
      end
    end
  
    parser_context = FeatureContext.new() do |c| 
      if partial_feature
        c.define_expansion_tag('entry') { |tg| tg.locals.entry = data[:entry]}
      else
        c.define_expansion_tag('wall') { |tg| data[:target] }
        c.define_expansion_tag('entry') { |tg| tg.locals.entry = data[:entry]}
        c.define_form_for_tag('form',:wall, :html => { :id => "wall_post_#{data[:paragraph].id}", :onsubmit => "WallEditor.submitPost(this); this.reset(); return false;" }) { |tg| data[:post] }
          c.define_field_tag('form:post',:field => :message,:control => 'text_area',:rows => 4, :cols => 30)
          c.define_button_tag('form:button')
        c.define_tag('entries') do |t| <<-EOF
          <script>
            var WallEditor = { 
              removeEntry: function(wall_id,entry_id) {
                if(confirm("Remove wall post?")) {
                  var params = "target_hash=#{data[:target_hash]}&remove_message[" + wall_id + "]=" + entry_id;
                  Effect.Fade('wall_' + wall_id + '_' + entry_id, { duration: 0.5});
                  new Ajax.Request('#{ajax_url}',{ parameters: params });
                }
              }, 
              offset: 1,
              fetchMore: function(wall_id) {
                this.offset += 1
                var params = 'target_hash=#{data[:target_hash]}&wall_page=' + this.offset;
                new Ajax.Updater('wall_#{data[:paragraph].id}','#{ajax_url}',{ insertion: 'bottom', parameters :params });
              },
              submitPost: function(frm) {
                var params = "target_hash=#{data[:target_hash]}&" +  Form.serialize(frm)
                new Ajax.Updater('wall_#{data[:paragraph].id}','#{ajax_url}',{ parameters :params });
              }
            }
          </script>
          <div id='wall_#{data[:paragraph].id}'>#{t.expand}</div>
          
          EOF
        end
        
        c.define_tag('entry') do |t| 
          container = t.attr['tag'] || "div"
          
          c.each_local_value(data[:entries],t,'entry')  do |entry,tg|
            "<#{container} id='wall_#{data[:paragraph].id}_#{entry.id}'>" + tg.expand + "</#{container}>"
          end
        end
        c.define_link_tag('more') do |t|
          if data[:more]
            { :href => 'javascript:void(0);',
              :onclick => "this.style.display = 'none'; WallEditor.fetchMore(#{data[:paragraph].id});" }
          end
        end
      end
      
      c.define_image_tag('entry:img') { |tag| tag.locals.entry.end_user ? tag.locals.entry.end_user.image : nil }
      c.define_value_tag('entry:user_id') { |t| t.locals.entry.end_user_id }
      c.define_expansion_tag('entry:edit') { |t| (t.locals.entry.end_user_id == myself.id) || data[:can_edit] }
        c.define_link_tag('entry:remove') do |t| 
          { :href => 'javascript:void(0);',
            :onclick => "WallEditor.removeEntry(#{data[:paragraph].id},#{t.locals.entry.id});" }
      end
      c.define_value_tag('entry:name') { |tag| tag.locals.entry.end_user ? tag.locals.entry.end_user.name : 'Anonymous' }
      c.define_date_tag('entry:date',  "On %a, %B %d") { |tag| tag.locals.entry.created_at }
      c.define_value_tag('entry:message') { |tag| h(tag.locals.entry.message).gsub("\n","<br/>") }
    end
    parse_feature(feature,parser_context)
  end
      
  
  
end
