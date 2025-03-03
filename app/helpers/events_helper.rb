# Functions to display events for activity feed
module EventsHelper
  def fontawesome_classes(event)
    kit = event.icon == 'thumbs-up' ? 'far' : 'fas'
    "#{kit} fa-#{event.icon}"
  end

  def entry_text(event)
    time = event.created_at.display_time.to_s
    cm = event.cm_name
    pt_link = link_to event.patient_name,
                      edit_patient_path(event.patient_id)
    call_list_link = link_to "(#{t('events.add_to_call_list')})",
                             add_patient_path(event.patient_id),
                             method: :patch,
                             remote: true

    safe_join [time, '--', cm, pt_link, call_list_link], ' '
  end
end
