

class Social::Autopublish

  def self.blog_targeted_after_publish_handler_info
   { :name => 'Social Auto Publish' }
  end
  
  def self.after_publish(blog_post,user)


    if blog_post.blog_blog.target_type == 'SocialUnit' && Social::AdminController.module_options.email_member_template_id
      social_unit = blog_post.blog_blog.targeted_blog

      social_unit.run_worker(:published_blog_post, { :blog_post_id => blog_post.id })
    end
  end


end
