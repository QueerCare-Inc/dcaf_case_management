# Object representing a case manager.
# Fields are all devise settings; most of the methods relate to call list mgmt.
class User < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  # include CallListable #TODO: revisit calls and houw they're structured

  # Devise modules
  devise  :database_authenticatable,
          :registerable,
          :recoverable,
          :trackable,
          :lockable,
          :timeoutable,
          :password_archivable,
          :session_limitable,
          :omniauthable, omniauth_providers: [:google_oauth2]
  # :validatable, # We override this to accommodate tenancy
  # :rememberable
  # :confirmable

  # Constants
  MIN_PASSWORD_LENGTH = 8
  TIME_BEFORE_DISABLED_BY_ORG = 9.months # NOTE: disable time here
  SEARCH_LIMIT = 15

  # Enums
  enum :role, {
    care_coordinator: 0,
    data_volunteer: 1,
    admin: 2,
    cr: 3, # care recipient
    volunteer: 4, # in person volunteer
    finance_admin: 5, # finance admin
    coord_admin: 6 # care coordination admin
  }

  # Callbacks
  before_validation :clean_fields
  after_update :send_password_change_email, if: :needs_password_change_email?
  after_create :send_account_created_email, if: :persisted?

  # Relationships
  # has_many :call_list_entries # TODO: this should be only used for care coordinators, care_coordinator admin?, finance admin?
  has_many :auth_factors, dependent: :destroy
  belongs_to :region, optional: true
  # has_one :person, as: :person, foreign_key: :id, inverse_of: :user, required: false
  has_one :person
  has_one :patient, required: false
  has_one :volunteer, required: false
  has_one :care_coordinator, required: false

  # Validations
  validates :name,
            :primary_phone,
            :region,
            :role,
            :email,
            presence: true
  validates :primary_phone, format: /\A\d{10}\z/,
                            length: { is: 10 }
  validate :confirm_unique_phone_number

  # email presence validated through Devise
  validates_uniqueness_to_tenant :email, allow_blank: true, if: :email_changed?

  validates :name,
            format: {
              with: %r{\A[^0-9`!@#$%\^&*+_=./]*\z},
              message: "may not include numbers or the following symbols: `!@\#$%^&*+_=./"
            },
            if: :name_changed?
  validates :email, format: { with: Devise.email_regexp }
  validate :secure_password, if: :updating_password?
  # i18n-tasks-use t('errors.messages.password.password_strength')
  validates :password, password_strength: { use_dictionary: true }, if: :updating_password?
  validates :name, :region, :email, :primary_phone, length: { maximum: 150 }

  # To accommodate tenancy, we use our own devise validations
  # See https://github.com/heartcombo/devise/blob/master/lib/devise/models/validatable.rb
  validates :email, format: { with: Devise.email_regexp, allow_blank: true, if: :email_changed? }
  validates :password, presence: { if: :password_required? }
  validates :password, confirmation: { if: :password_required? }
  validates :password, length: { within: MIN_PASSWORD_LENGTH..100, allow_blank: true }

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
  # end boilerplate from validatable

  def updating_password?
    !password.nil?
  end

  def secure_password
    pc = verify_password_complexity
    return unless pc == false

    errors.add :password, 'Password must include at least one lowercase ' \
                          'letter, one uppercase letter, and one digit. ' \
                          "Forbidden words include #{ActsAsTenant.current_tenant.name} and password."
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    User.find_by! email: data['email']
  end

  def toggle_disabled_by_org
    # Since toggle skips callbacks...
    attrs = { disabled_by_org: !disabled_by_org }
    # if we're currently locked, count this unlocking as a sign-in to avoid rapid relocking
    attrs.merge!({ current_sign_in_at: Time.zone.now }) if disabled_by_org?
    update attrs
  end

  def self.disable_inactive_users
    cutoff_date = Time.zone.now - TIME_BEFORE_DISABLED_BY_ORG

    inactive_has_logged_in = where('current_sign_in_at < ?', cutoff_date)
                             .where.not(role: [:admin])
    inactive_no_logins = where('created_at < ?', cutoff_date)
                         .where(current_sign_in_at: nil)
                         .where.not(role: [:admin])

    [inactive_no_logins, inactive_has_logged_in].each do |set|
      set.update disabled_by_org: true
    end
  end

  def save_identifier
    # [Region first initial][Phone 6th digit]-[Phone last four]
    self.identifier = "#{region.name[0].upcase}#{primary_phone[-5]}-#{primary_phone[-4..-1]}"
  end

  def initials
    name.split(' ').map { |part| part[0] }.join('')
  end

  def confirm_unique_phone_number
    ##
    # This method is preferred over Rail's built-in uniqueness validator
    # so that case managers get a meaningful error message when a patient
    # exists on a different region than the one the volunteer is serving.
    #
    # See https://github.com/DCAFEngineering/dcaf_case_management/issues/825
    ##
    phone_match = User.where(primary_phone: primary_phone).first

    return unless phone_match
    # skip when an existing patient updates and matches itself
    return if phone_match.id == id

    users_region = phone_match.region
    volunteers_region = region
    if volunteers_region == users_region
      errors.add(:this_phone_number_is_already_taken, 'on this region.')
    else
      errors.add(:this_phone_number_is_already_taken,
                 "on the #{users_region.name} region. If you need the user's region changed, please contact the care coordinator directors.")
    end
  end

  def allowed_data_access? # TODO: should this include care coordinators? finance admin?, care_coordinator admin?
    admin? || data_volunteer?
  end

  def self.search(name_or_email_str)
    return if name_or_email_str.blank?

    wildcard = "%#{name_or_email_str}%"
    User.where('name ilike ?', wildcard)
        .or(User.where('email ilike ?', wildcard))
        .order(updated_at: :desc)
        .limit(SEARCH_LIMIT)
  end

  def force_logout
    update_attribute(:session_validity_token, nil)
  end

  def create_new_person
    Person.create(
      user_id: id,
      region_id: region_id,
      org_id: org_id
      # region: region
    )
  end

  private

  def verify_password_complexity
    return false unless password.length >= MIN_PASSWORD_LENGTH # length at least 8
    return false if (password =~ /[a-z]/).nil? # at least one lowercase
    return false if (password =~ /[A-Z]/).nil? # at least one uppercase
    return false if (password =~ /[0-9]/).nil? # at least one digit

    # Make sure no bad words are in there
    org = ActsAsTenant.current_tenant.name.downcase
    return false unless password.downcase[/(password|#{org})/].nil?

    true
  end

  def needs_password_change_email?
    encrypted_password_changed? && persisted?
  end

  def send_password_change_email
    # @user = User.find(id)
    UserMailer.password_changed(id).deliver_now
  end

  def send_account_created_email
    UserMailer.account_created(id).deliver_now
  end

  def clean_fields
    primary_phone.gsub!(/\D/, '') if primary_phone
    name.strip! if name
  end
end
