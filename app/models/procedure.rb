# Object representing core patient information and demographic data.
class Procedure < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include Notetakeable
  include AttributeDisplayable
  # include Statusable
  include ProcedureTypeable
  include CareAddressListable
  include DateDisplayable
  include ServiceTypeable

  # Callbacks

  # Relationships
  belongs_to :region
  belongs_to :patient
  belongs_to :care_request_entry
  accepts_nested_attributes_for :care_request_entry
  # has_one :care_coordinator, through: :patient, optional: true
  belongs_to :care_coordinator, optional: true
  has_one :clinic
  has_one :surgeon
  has_many :shift_entries, dependent: :destroy
  has_many :care_addresses, through: :shift_entries, dependent: :destroy
  has_many :shifts, through: :shift_entries, dependent: :destroy
  has_many :reimbursements, as: :can_reimburse
  # has_many :notes, as: :can_note

  encrypts :procedure_date
  encrypts :service_start
  encrypts :intensive_service_end
  encrypts :service_end
  encrypts :intake_date

  enum :procedure_type, {
    not_specified: 0,
    mastectomy: 1,
    breast_augmentation: 2,
    breast_reduction: 3,
    hysterectomy: 4,
    orchiectomy: 5,
    vaginectomy: 6,
    metoidioplasty: 7,
    vaginoplasty: 8,
    phalloplasty: 9,
    facial_feminization: 10,
    facial_masculinization: 11,
    other: 99
  }

  enum :care_status, {
    new_care_request: 0,
    coordinator_assigned: 1,
    intake_complete: 2,
    accepted_care_request: 3,
    procedure_confirmed: 4,
    under_care: 5,
    care_complete: 6,
    rejected_care_request: 7,
    archived: 8
  }

  validates :procedure_type, presence: true, inclusion: { in: Procedure.procedure_types }
  validates :care_status, presence: true, inclusion: { in: Procedure.care_statuses }

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  validates :patient,
            :procedure_date,
            presence: true
  # validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/

  validate :confirm_appointment_after_intake

  validate :services_length
  validate :reimbursements_length
  validate :must_have_patient

  # Methods
  def okay_to_destroy?
    false
  end

  def notes_count
    notes.size
  end

  def has_services
    services.map { |service| service.present? }.any?
  end

  def has_reimbursements
    reimbursements.map { |reimbursement| reimbursement.present? }.any?
  end

  # TODO: update for new archiving timeline
  # def archive_date
  #   if fulfillment.audited?
  #     # If a patient fulfillment is ticked off as audited, archive 3 months
  #     # after initial call date. If we're already past 3 months later when
  #     # the audit happens, it will archive that night
  #     intake_date + Config.archive_fulfilled_patients.days
  #   else
  #     # If a patient is waiting for audit they archive a year after their
  #     # initial call date
  #     intake_date + Config.archive_all_patients.days
  #   end
  # end

  # def recent_history_tracks
  #   versions.where(updated_at: 6.days.ago..)
  # end

  def all_versions(include_fulfillment)
    all_versions = versions || []
    all_versions += practical_supports.includes(versions: [:item, :user]).map(&:versions).reduce(&:+) || []
    if include_fulfillment
      all_versions += fulfillment.versions.includes(fulfillment.versions.count > 1 ? [:item, :user] : []) || []
    end
    all_versions.sort_by(&:created_at).reverse
  end

  # Procedure Status Validation
  # care_progress
  #   new_care_request
  #   coordinator_assigned
  #   intake_complete
  #   accepted_care_request
  #   procedure_confirmed
  #   under_care
  #   care_complete
  #   rejected_care_request
  #   archived
  # TODO: add others?

  # def get_patient
  #   Patient.where(id: patient_id)
  # end

  # def get_care_coordinator_id
  #   patient = get_patient
  #   Care_Coordinator.where(id: patient.care_coordinator_id).id
  # end

  def get_clinic
    Clinic.where(id: clinic_id).first
  end

  def create_new_care_address
    CareAddress.new(
      org_id: org_id,
      region_id: region_id,
      patient_id: patient_id,
      procedure_id: id,
      street_address: '',
      city: '',
      state: '',
      zip: '00000',
      phone_number: '+15555555555',
      start_date: Date.parse(procedure_date) + 1.day,
      end_date: Date.parse(procedure_date) + 1.month
    )
  end

  def create_new_shift(care_address_id)
    Shift.new(
      org_id: org_id,
      region_id: region_id,
      patient_id: patient_id,
      care_address_id: care_address_id,
      procedure_id: id,
      shift_type: :other_shift,
      services: [],
      start_time: DateTime.now,
      end_time: DateTime.now + 1.hour
    )
  end

  # General shift times
  # # 1. Morning: 8:00 AM - 12:00 PM
  # services: personal_care, meals, chores, grocery_shopping, prescriptions, transportation, companionship, other
  # # 2. Afternoon: 12:00 PM - 4:00 PM
  # services: personal_care, meals, chores, grocery_shopping, prescriptions, transportation, companionship, other
  # # 3. Evening: 4:00 PM - 8:00 PM
  # services: personal_care, meals, chores, grocery_shopping, prescriptions, transportation, companionship, other
  # # 4. Overnight: 8:00 PM - 8:00 AM
  # services: personal_care, companionship, other

  def generate_shifts
    require 'parallel'
    require 'concurrent'

    # Capture the current tenant
    current_tenant = ActsAsTenant.current_tenant

    shift_entries_to_create = Concurrent::Array.new
    intensive_end_date = Date.parse(intensive_service_end)
    shift_times = [
      { start_hour: 8, end_hour: 12, shift_type: :in_home,
        services: %w[personal_care meals chores grocery_shopping prescriptions transportation companionship other_service] },
      { start_hour: 12, end_hour: 16, shift_type: :in_home,
        services: %w[personal_care meals chores grocery_shopping prescriptions transportation companionship other_service] },
      { start_hour: 16, end_hour: 20, shift_type: :in_home,
        services: %w[personal_care meals chores grocery_shopping prescriptions transportation companionship other_service] },
      { start_hour: 20, end_hour: 8, shift_type: :overnight,
        services: %w[personal_care companionship other_service], overnight: true }
    ]
    valid_care_addresses = care_address_list(self).where.not(start_date: nil, end_date: nil)

    Parallel.each(valid_care_addresses, in_threads: 4) do |care_address|
      # Set the tenant in each thread
      ActsAsTenant.current_tenant = current_tenant

      start_date = Date.parse(care_address.start_date)
      end_date = Date.parse(care_address.end_date)

      (start_date..end_date).each do |date_now|
        # Morning, Afternoon, and Evening shifts
        shift_times.each do |shift_time|
          # Overnight shift
          next if shift_time[:overnight] && (date_now > intensive_end_date || date_now > end_date)

          start_time = Time.zone.local(date_now.year, date_now.month, date_now.day, shift_time[:start_hour], 0)
          end_time = Time.zone.local(date_now.year, date_now.month, date_now.day, shift_time[:end_hour], 0)
          end_time += 1.day if shift_time[:overnight]

          ActiveRecord::Base.transaction do
            # Find the overlap between self.services and shift_time[:services]
            services = (self.services || []) & shift_time[:services]
            formatted_services = string_services_to_symbols(services)

            # Check if the shift already exists
            shift = Shift.find_or_create_by!(
              procedure_id: id,
              care_address_id: care_address.id,
              start_time: start_time,
              end_time: end_time
            ) do |new_shift|
              new_shift.org_id = org_id
              new_shift.region_id = region_id
              new_shift.patient_id = patient_id
              new_shift.shift_type = shift_time[:shift_type]
              new_shift.services = formatted_services.map(&:to_s)
            end

            # Check if the shift entry already exists
            unless ShiftEntry.exists?(
              procedure_id: id,
              care_address_id: care_address.id,
              shift_id: shift.id
            )
              # Add the shift entry to the list of shift entries to create
              shift_entries_to_create << {
                org_id: org_id,
                region_id: region_id,
                care_coordinator_id: nil,
                patient_id: patient_id,
                volunteer_id: nil, # Set this to `nil` initially; assign volunteers later
                procedure_id: id,
                care_address_id: care_address.id,
                shift_id: shift.id,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              }
            end
          end
        end
      end
    end

    # Perform bulk insert for shift entries
    ShiftEntry.insert_all(shift_entries_to_create) if shift_entries_to_create.any?

    shift_entries_to_create.any?
  end

  def get_all_shifts
    @procedure = Procedure.find(params[:id])
    @shifts = @procedure.shifts.order(:start_time) # Fetch and sort shifts
  end

  def get_page_shifts(page, per_page = 10)
    # shifts = Shift.where(procedure_id: id)
    sorted_shifts = # Sort in Ruby
      shifts.sort_by do |shift|
        DateTime.parse(shift.start_time)
            rescue StandardError
              nil
      end
    Kaminari.paginate_array(sorted_shifts).page(page).per(per_page) # Paginate in memory
  end

  private

  def string_services_to_symbols(services)
    services.map(&:to_sym).select do |service|
      ServiceTypeable::SERVICES.key?(service)
    end
  end

  def confirm_appointment_after_intake
    return unless intake_date.present?
    return unless procedure_date.present? && Date.parse(intake_date).after?(Date.parse(procedure_date))

    errors.add(:procedure_date, 'must be after date of intake')
  end

  # This is intended to protect against saving maliscious data sent via an edited request. It should
  # not be possible to trigger errors here via the UI.
  def services_length
    # The max length is (2 x n) where n is the number of services checkboxes. With no
    # boxes checked, there are n elements (all blank), and there is an additional element present
    # for every checked box.
    errors.add(:services, 'is invalid') unless services.length <= 14

    services.each do |value|
      errors.add(:services, 'is invalid') if value && value.length > 50
    end
  end

  def reimbursements_length
    errors.add(:reimbursements, 'is invalid') unless reimbursements.length <= 50

    reimbursements.each do |value|
      errors.add(:reimbursements, 'is invalid') if value && value.length > 50
    end
  end

  def must_have_patient
    errors.add(:patient, I18n.t('errors.procedure.must_have_patient')) unless patient.present?
  end

  def create_care_request_entry
    CareRequestEntry.create!(
      patient: patient,
      procedure: self,
      care_coordinator: care_coordinator,
      region: region
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create CareRequestEntry: #{e.message}"
  end
end
