module NavbarHelper
  def care_coordinator_resources_link
    maybe_url = Config.find_or_create_by(config_key: 'resources_url').options.first

    # redundant UriService just for fallbackhelp
    url = UriService.new(maybe_url).uri

    return unless url.present?

    content_tag :li do
      link_to t('navigation.care_coordinator_resources.label'), url.to_s, target: '_blank', class: 'nav-link',
                                                                          rel: 'noopener'
    end
  end

  def spanish_or_english_link
    content_tag :li do
      if I18n.locale == I18n.default_locale
        link_to 'Español', { locale: 'es' }, class: 'nav-link'
      else
        link_to 'English', { locale: 'en' }, class: 'nav-link'
      end
    end
  end
end
