# Object representing core patient information and demographic data.
class Procedure < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include Notetakeable
  include Statusable

  # Callbacks
  # before_validation :clean_fields

  # Relationships
  belongs_to :region
  belongs_to :patient
  has_one :clinic
  has_one :surgeon
  has_many :shifts, as: :can_shift
  has_many :care_addresses, as: :can_care_address
  has_many :reimbursements, as: :can_reimburse
  # has_many :notes, as: :can_note
  # belongs_to :last_edited_by, class_name: 'User', inverse_of: nil, optional: true

  # enum :procedure_type, {
  #   not_specified: :not_specified, #0,
  #   mastectomy: :mastectomy, #1,
  #   breast_augmentation: :breast_augmentation, #2,
  #   metoidioplasty: :metoidioplasty, #3,
  #   vaginoplasty: :vaginoplasty, #4,
  #   phalloplasty: :phalloplasty, #5,
  #   facial_feminization: :facial_feminization, #6,
  #   facial_masculinization: :facial_masculinization, #7,
  #   other: :other, #99
  # }

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  validates :patient,
            :region,
            # :surgeon,
            # :clinic,
            :procedure_date,
            :procedure_type,
            :care_status,
            presence: true
  validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/
  validate :confirm_appointment_after_intake

  # validates :surgeon, :clinic, 
  validates :procedure_type, length: { maximum: 150 }

  validate :services_length
  validate :reimbursements_length
  validate :care_progress_length

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

  # def all_versions(include_fulfillment)
  #   all_versions = versions || []
  #   all_versions += practical_supports.includes(versions: [:item, :user]).map(&:versions).reduce(&:+) || []
  #   if include_fulfillment
  #     all_versions += fulfillment.versions.includes(fulfillment.versions.count > 1 ? [:item, :user] : []) || []
  #   end
  #   all_versions.sort_by(&:created_at).reverse
  # end

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

  def validate_care_progress_status?
    # debugger
    if care_progress[7]
      care_status == 'rejected_care_request'
    elsif care_progress[8]
      care_status == 'archived'
    elsif care_progress[0] && care_progress.values_at(1..-1).none?
      care_status == 'new_care_request'
    elsif care_progress.values_at(0..1).all? && care_progress.values_at(2..-1).none?
      care_status == 'coordinator_assigned'
    elsif care_progress.values_at(0..2).all? && care_progress.values_at(3..-1).none?
      care_status == 'intake_complete'
    elsif care_progress.values_at(0..3).all? && care_progress.values_at(4..-1).none?
      care_status == 'accepted_care_request'
    elsif care_progress.values_at(0..4).all? && care_progress.values_at(5..-1).none?
      care_status == 'procedure_confirmed'
    elsif care_progress.values_at(0..5).all? && care_progress.values_at(6..-1).none?
      care_status == 'under_care'
    elsif care_progress.values_at(0..6).all?
      care_status == 'care_complete'
    end
  end

  private

  def confirm_appointment_after_intake
    return unless procedure_date.present? && intake_date&.send(:>, procedure_date)

    errors.add(:procedure_date, 'must be after date of intake')
  end

  def get_patient
    Patient.where(id: patient_id)
  end

  def get_care_coordinator_id
    patient = get_patient
    Care_Coordinator.where(id: patient.care_coordinator_id).id
  end

  # def clean_fields
  #   emergency_contact_phone.gsub!(/\D/, '') if emergency_contact_phone
  #   emergency_contact.strip! if emergency_contact
  #   emergency_contact_relationship.strip! if emergency_contact_relationship

  #   # add dash if needed
  #   zipcode.gsub!(/(\d{5})(\d{4})/, '\1-\2') if zipcode
  # end

  # def self.unconfirmed_practical_support(region)
  #   Procedure.distinct
  #            .where(region: region)
  #            .joins(:practical_supports)
  #            .where({ practical_supports: { confirmed: false }, created_at: 3.months.ago.. })
  # end

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

  def care_progress_length
    errors.add(:care_progress, 'is invalid') unless care_progress.length <= 10
  end

  
end
