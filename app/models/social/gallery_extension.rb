
class Social::GalleryExtension < DomainModelExtension



def after_save(gi)
    if gi.position == 1
      if gi.gallery.container_type == 'EndUser'
        gi.gallery.container.update_attribute(:domain_file_id,gi.domain_file_id)
      end
    end
end

def before_destroy(gi)
  
  if gi.position == 1
    if gi.gallery.container_type == 'EndUser'
      if new_img = gi.gallery.gallery_images.find(:first,:order => 'position',:conditions => ['gallery_images.id != ?',gi.id ])
        gi.gallery.container.update_attribute(:domain_file_id,new_img.domain_file_id)
      end
    end
  end
end



end
