# Methods pertaining to person search
module PersonSearchable
  extend ActiveSupport::Concern

  DEFAULT_SEARCH_LIMIT = 15

  class_methods do
    # Case insensitive and phone number format agnostic!
    # pass `search_limit: nil` for no limit.
    def search(name_or_phone_str, regions: nil, search_limit: DEFAULT_SEARCH_LIMIT, person_subtype: nil)
      wildcard_name = "%#{name_or_phone_str}%"
      clean_phone = name_or_phone_str.gsub(/\D/, '')

      base_user = User.where(region_id: regions.map { |x| x.id }) if regions
      if person_subtype == 'Patient'
        base_user = base_user.where(role: :cr)
      elsif person_subtype == 'Volunteer'
        base_user = base_user.where(role: :volunteer)
      elsif person_subtype == 'CareCoordinator'
        base_user = base_user.where(role: :care_coordinator)
      elsif person_subtype == 'FinanceAdmin'
        base_user = base_user.where(role: :finance_admin)
      elsif person_subtype == 'Admin'
        base_user = base_user.where(role: :admin)
      elsif person_subtype == 'CoordAdmin'
        base_user = base_user.where(role: :coord_admin)
      end

      user_matches = base_user.where('name ilike ?', wildcard_name)
      if clean_phone.present?
        clean_phone_str = "%#{clean_phone}%"
        user_matches = user_matches.or(base_user.where('primary_phone like ?', clean_phone_str))
      end

      base_person = Person
      base_person = base_person.where(region_id: regions.map { |x| x.id }) if regions # is this right?

      person_matches = base_person.where('emergency_contact ilike ?', wildcard_name)
                                  .or(base_person.where('identifier ilike ?', wildcard_name))
      if clean_phone.present?
        person_matches = person_matches.or(base_person.where('emergency_contact_phone like ?',
                                                             clean_phone_str))
      end

      person_matches = person_matches.or(base_person.where(user_id: user_matches.map { |x| x.id })) if user_matches
      person_matches = person_matches.order(updated_at: :desc)

      if person_subtype.nil?
        person_matches.limit(search_limit) if search_limit.present?
      else
        base_subtype = person_subtype
        subtype_matches = base_subtype.where(person_id: person_matches.map { |x| x.id }) if person_matches

        if subtype_matches.length > 0
          people = base_person.where(id: subtype_matches.map { |x| x.person_id })

          people = people.order(updated_at: :desc)
          people.limit(search_limit) if search_limit.present?
        else
          []
        end
      end
    end
  end
end
