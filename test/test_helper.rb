require 'simplecov'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/autorun'
require 'capybara/rails'
require 'capybara-screenshot/minitest'
require 'omniauth_helper'
require 'integration_helper'
require 'rack/test'

# CI only
if ENV['CI']
  # Save screenshots if system tests fail
  Capybara.save_path = Rails.root.join('tmp/capybara')
end

# Convenience methods around config creation, and database cleaning
class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  before do
    setup_tenant
  end

  after do
    teardown_tenant
  end

  parallelize(workers: :number_of_processors) unless ENV['DOCKER']

  def setup_tenant
    tenant = create :org, name: 'CATF', full_name: 'Cat Fund'
    ActsAsTenant.current_tenant = tenant
    ActsAsTenant.test_tenant = tenant
  end

  def teardown_tenant
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end

  def create_insurance_config
    insurance_options = ['DC Medicaid', 'Other state Medicaid']
    create :config, config_key: 'insurance',
                    config_value: { options: insurance_options }
  end

  def create_procedure_type_config(procedure_type_options)
    create :config, config_key: 'procedure_type',
                    config_value: { options: procedure_type_options }
  end

  def create_county_config
    county_options = %w[Arlington Fairfax Montgomery]
    create :config, config_key: 'county',
                    config_value: { options: county_options }
  end

  def create_practical_support_config
    practical_support_options = ['Metallica Tickets', 'Clothing']
    create :config, config_key: 'practical_support',
                    config_value: { options: practical_support_options }
  end

  def create_language_config
    language_options = %w[Spanish French Korean]
    create :config, config_key: 'language',
                    config_value: { options: language_options }
  end

  def create_voicemail_config
    vm_options = ['Text Message Only', 'Use Codename', 'Only During Business Hours']
    create :config, config_key: 'voicemail',
                    config_value: { options: vm_options }
  end

  def create_referred_by_config
    referred_by_options = ['Metal band']
    create :config, config_key: 'referred_by',
                    config_value: { options: referred_by_options }
  end

  def create_fax_service_config
    create :config, config_key: 'fax_service',
                    config_value: { options: ['http://www.efax.com'] }
  end

  def create_hide_defaults_config(should_hide: true)
    c = Config.find_or_create_by(config_key: 'hide_standard_dropdown_values')
    c.config_value = { options: [should_hide ? 'yes' : 'no'] }
    c.save!
  end

  def create_display_practical_support_attachment_url_config(on: true)
    c = Config.find_or_create_by(config_key: 'display_practical_support_attachment_url')
    c.config_value = { options: [on ? 'yes' : 'no'] }
    c.save!
  end

  def create_display_practical_support_waiver_config(on: true)
    c = Config.find_or_create_by(config_key: 'display_practical_support_waiver')
    c.config_value = { options: [on ? 'yes' : 'no'] }
    c.save!
  end

  def with_versioning(user = nil, &block)
    was_enabled = PaperTrail.enabled?
    was_enabled_for_request = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true
    begin
      if user
        PaperTrail.request(whodunnit: user.id, &block)
      else
        yield
      end
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.request.enabled = was_enabled_for_request
    end
  end
end

# Used by controller tests
class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Screenshot::MiniTestPlugin
  include IntegrationHelper
  include OmniauthMocker
  OmniAuth.config.test_mode = true

  before { Capybara.reset_sessions! }

  # for controllers
end
