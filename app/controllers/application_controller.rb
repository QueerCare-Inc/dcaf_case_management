# Sets a few devise configs and security measures
class ApplicationController < ActionController::Base
  set_current_tenant_by_subdomain(:org, :subdomain)

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception

  prepend_before_action :authenticate_user!, unless: -> { try(:errors_controller?) }
  prepend_before_action :confirm_user_not_disabled!, unless: -> { devise_controller? || try(:errors_controller?) }

  before_action :confirm_tenant_set_development if Rails.env.development?
  before_action :confirm_tenant_set_test if Rails.env.test?
  before_action :redirect_if_legacy
  before_action :confirm_tenant_set
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :prevent_caching_via_headers
  before_action :set_locale
  before_action :set_sentry_context
  before_action :set_paper_trail_whodunnit
  before_action :set_time_zone, if: :user_signed_in?

  # redirect to new system if config is set
  def redirect_if_legacy
    return unless ENV['REDIRECT_DESTINATION'].present?

    redirect_to ENV['REDIRECT_DESTINATION']
  end

  # Don't let any requests through without confirming a tenant is set.
  def confirm_tenant_set
    # There's an ActsAsTenant config method that does this too,
    # but we do it here so we can control when it runs.
    return unless ActsAsTenant.current_tenant.nil? && !ActsAsTenant.unscoped?

    raise ActsAsTenant::Errors::NoTenantSet
  end

  # In development only, set first org as tenant by default.
  def confirm_tenant_set_development
    # If you need to access the other org in dev, hit catbox.lvh.me:3000
    # to tunnel in.
    return unless ActsAsTenant.current_tenant.nil? && !ActsAsTenant.unscoped?

    # If this errors, make sure you've run rails db:seed to populate db!
    ActsAsTenant.current_tenant = Org.find_by! name: 'CatFund'
  end

  # In test only, set CATF org as tenant by default.
  def confirm_tenant_set_test
    return unless ActsAsTenant.current_tenant.nil? && !ActsAsTenant.unscoped?

    ActsAsTenant.current_tenant = Org.find_by! name: 'CATF'
  end

  # allowlist attributes in devise
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update) do |user|
      user.permit :name, :current_password, :password, :password_confirmation
    end
  end

  def set_locale
    I18n.locale = (params[:locale].presence || I18n.default_locale)
  end

  def default_url_options
    return { locale: I18n.locale } if I18n.locale != I18n.default_locale

    {}
  end

  private

  # Prevents app from caching pages as a security measure
  def prevent_caching_via_headers
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def confirm_admin_user
    redirect_to root_url unless current_user.admin?
  end

  def confirm_admin_user_async
    head :unauthorized unless current_user.admin?
  end

  def confirm_data_access
    redirect_to root_path unless current_user.allowed_data_access?
  end

  def confirm_data_access_async
    head :unauthorized unless current_user.allowed_data_access?
  end

  def confirm_user_not_disabled!
    return unless current_user.disabled_by_org?

    flash[:danger] = t('flash.account_locked')
    sign_out current_user
  end

  def set_sentry_context
    Sentry.set_user(id: current_user&.id)
    Sentry.set_extras(params: params.to_unsafe_h, url: request.url)
  end

  def set_time_zone
    # current_user from Devise. How do we implement this? Do we just want time zone or do we want other functionality from Devise?
    # Time.zone = current_user.time_zone
  end
end
