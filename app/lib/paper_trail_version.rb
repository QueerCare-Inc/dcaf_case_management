# Extensions to base class of PaperTrail.
class PaperTrailVersion < PaperTrail::Version
  acts_as_tenant :fund

  # Relations
  belongs_to :user, foreign_key: :whodunnit, optional: true

  IRRELEVANT_FIELDS = %w[
    id
    user_ids
    updated_by_id
    last_edited_by_id
    identifier
    updated_at
    created_at
    fund_id
    can_fulfill_type
    can_fulfill_id
    can_support_type
    can_support_id
  ].freeze
  DATE_FIELDS = %w[
    procedure_date
    intake_date
  ].freeze

  # convenience methods for clean view display
  def date_of_change
    created_at.display_date
  end

  def has_changed_fields?
    object_changes.keys.reject { |x| IRRELEVANT_FIELDS.include? x }.present?
  end

  def changed_by_user
    user&.name || 'System'
  end

  def shaped_changes
    changeset.reject { |field| IRRELEVANT_FIELDS.include? field }
             .reject { |_, values| values[0].blank? && values[1].blank? }
             .reduce({}) do |acc, x|
               key = x[0]
               acc.merge({ key => { original: format_fieldchange(key, x[1][0]),
                                    modified: format_fieldchange(key, x[1][1]) } })
             end
  end

  def marked_shared?
    (object_changes['shared_flag']&.last == true) || (object_changes['urgent_flag']&.last == true)
  end

  def self.destroy_old
    PaperTrailVersion.where('created_at < ?', 1.year.ago).destroy_all
  end

  private

  def format_fieldchange(key, value)
    if value.blank?
      '(empty)'
    elsif DATE_FIELDS.include? key
      year, month, day = value.split('-')
      "#{month.rjust(2, '0')}/#{day.rjust(2, '0')}/#{year}"
    #  elsif TIME_FIELDS.include? key
    #    year, month, day = value.gsub(/T.*/, '').split('-')
    #    "#{month.rjust(2, '0')}/#{day.rjust(2, '0')}/#{year}"
    elsif value.is_a? Array # special circumstances, for example
      value.reject(&:blank?).join(', ')
    elsif key == 'clinic_id'
      Clinic.find(value).name
    else
      value
    end
  end
end
