# Convenience function for displaying regions around the app.
module RegionsHelper
  def current_region_display
    return if !session[:region_id]

    # If multiple regions, link to the switcher
    if Region.count > 1
      return content_tag :li do
        link_to t('navigation.current_region.helper') + ": #{current_region.name}",
                new_region_path,
                class: 'nav-link navbar-text-alt'
      end
    end

    # Otherwise just display the content
    content_tag :li do
      content_tag :span, t('navigation.current_region.helper') + ": #{current_region.name}",
                         class: 'nav-link navbar-text-alt'
    end
  end

  def current_region
    Region.find_by_id session[:region_id]
  end
end
