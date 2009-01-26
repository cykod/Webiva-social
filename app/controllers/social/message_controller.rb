

class Social::MessageController < ParagraphController

  editor_header 'Social Networking Paragraphs'
  
  editor_for :wall, :name => 'Messaging Wall', :inputs => [ [ :wall_target, 'Wall Target', :target ] ], :no_options => true, :features => [ :social_message_wall ]
  
  editor_for :notify, :name => 'Social Notification'

  class WallOptions < HashModel
    attributes :per_page => 20
  end  
  
end
