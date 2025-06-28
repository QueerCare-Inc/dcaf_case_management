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

      base_person = Person
      base_person = base_person.where(region_id: regions.map { |x| x.id }) if regions # is this right?
      person_matches = base_person.where('name ilike ?', wildcard_name)
      if clean_phone.present?
        clean_phone_str = "%#{clean_phone}%"
        person_matches = person_matches.or(base_person.where('primary_phone like ?', clean_phone_str))
      end

      person_matches = person_matches.or(base_person.where('emergency_contact ilike ?', wildcard_name))
                                      .or(base_person.where('identifier ilike ?', wildcard_name))
      person_matches = person_matches.or(base_person.where('emergency_contact_phone like ?', clean_phone_str)) if clean_phone.present?
      person_matches = person_matches.order(updated_at: :desc)
      
      if person_subtype == nil
        person_matches.limit(search_limit) if search_limit.present?
      else
        base_subtype = person_subtype
        subtype_matches = base_subtype.where(person_id: person_matches.map { |x| x.id }) if person_matches

        if subtype_matches.length > 0
          people = base_person.where(id: subtype_matches.map{ |x| x.person_id })
          
          people = people.order(updated_at: :desc)
          people.limit(search_limit) if search_limit.present?
        else
          []
        end
      end
    end
  end
end
