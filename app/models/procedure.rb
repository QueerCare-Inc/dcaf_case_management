# Object representing core patient information and demographic data.
class Procedure < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include Notetakeable
  include AttributeDisplayable
  include Statusable
  include ProcedureTypeable
  include CareAddressListable

  # Callbacks

  # Relationships
  belongs_to :region
  belongs_to :patient
  has_one :clinic
  has_one :surgeon
  has_many :shifts, as: :can_shift
  has_many :care_addresses, as: :can_care_address
  has_many :reimbursements, as: :can_reimburse
  # has_many :notes, as: :can_note

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
            :region,
            :procedure_date,
            presence: true
  validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/
  validate :confirm_appointment_after_intake

  validate :services_length
  validate :reimbursements_length

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

  def get_patient
    Patient.where(id: patient_id)
  end

  def get_care_coordinator_id
    patient = get_patient
    Care_Coordinator.where(id: patient.care_coordinator_id).id
  end

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
      start_date: procedure_date + 1.day,
      end_date: procedure_date + 1.month
    )
  end

  def create_new_shift(care_address_id)
    Shift.new(
      org_id: org_id,
      region_id: region_id,
      patient_id: patient_id,
      care_address_id: care_address_id,
      procedure_id: id,
      type: 'other',
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
    for care_address in care_addresses
      next unless care_address.start_date.present? && care_address.end_date.present?

      # Create a shift for each care address
      for date_now in care_address.start_date..care_address.end_date
        for start_time, end_time in [[Time.zone.parse('08:00'), Time.zone.parse('12:00')],
                                     [Time.zone.parse('12:00'), Time.zone.parse('16:00')],
                                     [Time.zone.parse('16:00'), Time.zone.parse('20:00')]]

          shift = create_new_shift(care_address.id)
          shift.services = services && %w[personal_care meals chores grocery_shopping prescriptions
                                          transportation companionship other]
          shift.start_time = date_now.change(hour: start_time.hour, min: start_time.min)
          shift.end_time = date_now.change(hour: end_time.hour, min: end_time.min)
          shift.save
        end
        next unless date_now != care_address.end_date

        # Create an overnight shift if the end date is not the same as the start date
        shift = create_new_shift(care_address.id)
        shift.services = services && %w[personal_care companionship other]
        shift.start_time = date_now.change(hour: 20, min: 0) # 8:00 PM
        shift.end_time = (date_now + 1.day).change(hour: 8, min: 0) # 8:00 AM next day
        shift.save
      end
      # true if shifts.present?
      # false if shifts.empty?
    end
    false
  end

  private

  def confirm_appointment_after_intake
    return unless procedure_date.present? && intake_date&.send(:>, procedure_date)

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
end
