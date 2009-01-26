
class Social::SocialRenderer < ParagraphRenderer



  protected
  
  def social_user(usr)
    return @social_user if @social_user
    @social_user = SocialUser.user(usr) 
  end


end
