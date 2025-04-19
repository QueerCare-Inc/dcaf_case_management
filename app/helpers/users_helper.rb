# Functions for cleaner rendering of user panels.
module UsersHelper
  def user_role_options
    [
      ['Care coordinator', 'care_coordinator'], # renamed from Case manager, cm
      ['Data volunteer', 'data_volunteer'], # don't need?
      ['Admin', 'admin'],
      ['Care Recipient', 'cr'], # added
      ['Volunteer', 'volunteer'], # added
      ['Finance admin', 'finance_admin'], # added
      ['Care coordination admin', 'coord_admin'] # added
    ]
  end

  def user_lock_status(user)
    if user.disabled_by_org?
      'Locked by admin'
    elsif user.access_locked?
      'Temporarily locked'
    else
      'Active'
    end
  end

  def role_toggle_button(user, new_role)
    link_to "Change #{user.name}'s role to #{new_role.titleize}",
            public_send("change_role_to_#{new_role}_path", user),
            method: :patch,
            class: 'btn btn-warning'
  end

  def disabled_toggle_button(user)
    verb = user.disabled_by_org? ? 'Unlock' : 'Lock'
    link_to "#{verb} account",
            toggle_disabled_path(user),
            method: :post,
            class: 'btn btn-warning'
  end
end
