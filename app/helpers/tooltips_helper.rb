# Populate bootstrap tooltip text
module TooltipsHelper
  def tooltip_shell(help_text)
    content_tag :span, class: 'daria-tooltip tooltip-header-help',
                       data: { toggle: 'tooltip',
                               html: true,
                               placement: 'bottom',
                               title: help_text } do
      '(?)'
    end
  end

  def dashboard_table_content_tooltip_shell(table_type)
    return if table_type == 'search_results'

    method_name = "#{table_type}_help_text"
    help_text = public_send(method_name)
    tooltip_shell help_text
  end

  # TODO: add care coordinate options
  def care_coordinate_help_text
    t('tooltips.care_coordinate').strip
  end

  # def procedure_list_help_text
  #   t('tooltips.procedure_list').strip
  # end

  def new_care_requests_list_help_text
    t('tooltips.new_care_request_list').strip
  end

  def assigned_care_requests_list_help_text
    t('tooltips.assigned_care_requests_list').strip
  end

  def intake_complete_list_help_text
    t('tooltips.intake_complete_list').strip
  end

  def active_care_requests_list_help_text
    t('tooltips.active_care_requests_list').strip
  end

  def procedure_confirmed_list_help_text
    t('tooltips.procedure_confirmed_list').strip
  end

  def under_care_list_help_text
    t('tooltips.under_care_list').strip
  end

  def assigned_care_requests_list_help_text
    t('tooltips.assigned_care_requests_list').strip
  end

  def shared_cases_help_text
    t('tooltips.shared_cases', shared_reset: Config.shared_reset_days).strip
  end

  def procedure_list_help_text
    t('tooltips.procedure_list').strip
  end

  def unconfirmed_support_help_text
    t('tooltips.unconfirmed_support').strip
  end

  # TODO: add more tooltips for practical support
  def status_help_text(procedure)
    care_request_entry = CareRequestEntry.where(procedure: procedure).first
    care_status = care_request_entry.status_texts(procedure.care_status)

    status_def = "#{care_status[:key]}: #{care_status[:help_text]}"

    safe_join(["#{t('tooltips.status_definition')}:"].concat([status_def]), tag.br)
  end

  def referred_to_clinic_help_text
    t('tooltips.referred_to_clinic').strip
  end

  def patient_identifier_help_text
    t('tooltips.patient_identifier').strip
  end

  def practical_support_confirmed_help_text
    t('tooltips.practical_support_confirmed').strip
  end

  def practical_support_fulfilled_help_text
    t('tooltips.practical_support_fulfilled').strip
  end
end
