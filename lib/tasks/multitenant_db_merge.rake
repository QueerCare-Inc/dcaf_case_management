desc 'Merge an ext daria db into main db'
task multitenant_db_merge: :environment do
  raise 'SET MIGRATION_ORG_ID ENV VAR' if not ENV['MIGRATION_ORG_ID']
  raise 'SET MIGRATION_DB_URL ENV VAR' if not ENV['MIGRATION_DB_URL']

  # Make absolutely sure the new org has been created!
  org = Org.find ENV['MIGRATION_ORG_ID']
  @org_id = org.id

  # Scope orgs and turn off papertrail
  ActsAsTenant.current_tenant = org
  PaperTrail.enabled = false # We're porting these over more directly and don't need extra versions

  # Database we're migrating things into
  def connect_to_target_db
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  end

  # Database we're migrating things out of
  def connect_to_migration_db
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      encoding: 'unicode',
      pool: 10,
      url: ENV['MIGRATION_DB_URL']
    )
    ActiveRecord::Base.connection.execute(
      "SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY;"
    )
  end

  puts "Migrating into org_id #{@org_id}..."

  if Patient.count() > 0 || Config.count() > 0
    raise 'Possibly already ported? patients belonging to that org_id are found'
  end

  # Store the mappings between an old id and new id, and update them as we port the goods
  @config_mappings = {}
  @clinic_mappings = {}
  @region_mappings = {}
  @user_mappings = {}
  @call_mappings = {}
  @fulfillment_mappings = {}
  @practical_support_mappings = {}
  @note_mappings = {}
  @patient_mappings = {}
  @archived_patient_mappings = {}
  @call_list_entry_mappings = {}
  @event_mappings = {}

  # object agnostic function for handling each insert 
  def easy_mass_insert(model, tbl, map_func, check_counts = true)
    puts "#{Time.now} Porting #{model.to_s}"
    connect_to_migration_db
    obj_for_migrate = ActiveRecord::Base.connection.execute("select * from #{tbl} order by id asc")

    # This might happen in the case of ArchivedPatient
    if obj_for_migrate.ntuples.zero?
      puts "#{Time.now} No #{model} to port - zero found via query"
      return {}
    end

    connect_to_target_db
    clean_rows = obj_for_migrate.map { |x| map_func.call x }

    result = model.insert_all clean_rows.reject(&:nil?)

    # QA
    puts "#{Time.now} Ported #{model.count} #{model} and #{obj_for_migrate.ntuples} were in original db"
    raise "COUNT MISMATCH ERROR" unless model.count == obj_for_migrate.ntuples if check_counts

    # Map results to new ids
    id_mapping = {}
    result.rows.each_with_index do |x, i|
      id_mapping[obj_for_migrate[i]['id'].to_i] = x[0]
    end

    # Spot check
    puts "Spot check:"
    puts "Raw row: #{obj_for_migrate.first}"
    puts "Clean row: #{clean_rows[0]}"
    puts "Inserted record: #{model.find(id_mapping[obj_for_migrate.first['id']]).attributes}\n\n"

    id_mapping
  end

  # Create each object's lamba function for copying the object, including handling for the new org_id, cleaned timestamps, and any fields each model may need
  # Port configs
  config_map = -> (x) {
    x.except('id', 'org_id', 'config_value', 'created_at', 'updated_at')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
       'config_value' => JSON.parse(x['config_value'])
     })
  }
  @config_mappings = easy_mass_insert Config, 'configs', config_map

  # Port clinics
  clinic_map = -> (x) {
    x.except('id', 'org_id', 'created_at', 'updated_at')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York")
     })
  }
  @clinic_mappings = easy_mass_insert Clinic, 'clinics', clinic_map

  # Port regions
  region_map = -> (x) {
    x.except('id', 'org_id', 'created_at', 'updated_at')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York")
     })
  }
  @region_mappings = easy_mass_insert Region, 'regions', region_map

  # Port users
  user_map = -> (x) {
    x.except('id', 'org_id', 'region', 'created_at', 'updated_at')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York")
     })
  }
  @user_mappings = easy_mass_insert User, 'users', user_map

  # Port patients
  patient_map = -> (x) {
    x.except('id', 'org_id', 'created_at', 'updated_at', 'region_id', 'clinic_id', 'last_edited_by_id')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
       'region_id' => @region_mappings[x['region_id']],
       'clinic_id' => @clinic_mappings[x['clinic_id']],
       'last_edited_by_id' => @user_mappings[x['last_edited_by_id']]
     })
  }
  @patient_mappings = easy_mass_insert Patient, 'patients', patient_map

  # Port archived patients
  archived_patient_map = -> (x) {
    x.except('id', 'org_id', 'created_at', 'updated_at', 'region_id', 'clinic_id')
     .merge({
       'org_id' => @org_id,
       'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
       'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
       'region_id' => @region_mappings[x['region_id']],
       'clinic_id' => @clinic_mappings[x['clinic_id']]
     })
  }
  @archived_patient_mappings = easy_mass_insert ArchivedPatient, 'archived_patients', archived_patient_map

  # Note about subobjects: there are some abandoned records (e.g. from patients who were deleted)
  # so we don't count check on these
  # Port calls
  call_map = -> (x) {
    res = x.except('id', 'can_call_id', 'org_id', 'created_at', 'updated_at')
      .merge({
        'org_id' => @org_id,
        'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
        'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
        'can_call_id' => if x['can_call_type'] == 'Patient'
                           @patient_mappings[x['can_call_id']]
                         elsif x['can_call_type'] == 'ArchivedPatient'
                           @archived_patient_mappings[x['can_call_id']]
                         else
                           raise "unexpected type - row #{x}"
                         end
      })
    res['can_call_id'].nil? ? nil : res
  }
  @call_mappings = easy_mass_insert Call, 'calls', call_map, false

  # Port fulfillments
  fulfillment_map = -> (x) {
    res = x.except('id', 'created_at', 'updated_at', 'can_fulfill_id', 'org_id')
      .merge({
        'org_id' => @org_id,
        'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
        'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
        'can_fulfill_id' => if x['can_fulfill_type'] == 'Patient'
                              @patient_mappings[x['can_fulfill_id']]
                            elsif x['can_fulfill_type'] == 'ArchivedPatient'
                              @archived_patient_mappings[x['can_fulfill_id']]
                            else
                              raise "unexpected type - row #{x}"
                            end
      })
    res['can_fulfill_id'].nil? ? nil : res
  }
  @fulfillment_mappings = easy_mass_insert Fulfillment, 'fulfillments', fulfillment_map, false

  # Port practical supports
  psup_map = -> (x) {
    res = x.except('id', 'created_at', 'updated_at', 'can_support_id', 'org_id')
      .merge({
        'org_id' => @org_id,
        'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
        'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
        'can_support_id' => if x['can_support_type'] == 'Patient'
                           @patient_mappings[x['can_support_id']]
                         elsif x['can_support_type'] == 'ArchivedPatient'
                           @archived_patient_mappings[x['can_support_id']]
                         else
                           raise "unexpected type - row #{x}"
                         end
      })
    res['can_support_id'].nil? ? nil : res
  }
  @practical_support_mappings = easy_mass_insert PracticalSupport, 'practical_supports', psup_map, false

  # Port notes
  note_map = -> (x) {
    res = x.except('id', 'created_at', 'updated_at', 'org_id', 'patient_id')
           .merge({
             'org_id' => @org_id,
             'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
             'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
             'patient_id' => @patient_mappings[x['patient_id']]
           })
    res['patient_id'].nil? ? nil : res
  }
  @note_mappings = easy_mass_insert Note, 'notes', note_map, false

  # Port call list entries
  cle_map = -> (x) {
    res = x.except('id', 'created_at', 'updated_at', 'org_id', 'region_id', 'patient_id', 'user_id')
           .merge({
             'org_id' => @org_id,
             'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
             'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
             'region_id' => @region_mappings[x['region_id']],
             'patient_id' => @patient_mappings[x['patient_id']],
             'user_id' => @user_mappings[x['user_id']]
           })
    res['patient_id'].nil? ? nil : res
  }
  @call_list_entry_mappings = easy_mass_insert CallListEntry, 'call_list_entries', cle_map, false

  # Port events
  event_map = -> (x) {
    res = x.except('id', 'created_at', 'updated_at', 'org_id', 'region_id', 'patient_id')
           .merge({
             'org_id' => @org_id,
             'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
             'updated_at' => x['updated_at'].asctime.in_time_zone("America/New_York"),
             'region_id' => @region_mappings[x['region_id']],
             'patient_id' => @patient_mappings[x['patient_id'].to_i],
           })
    res['patient_id'].nil? ? nil : res
  }
  @event_mappings = easy_mass_insert Event, 'events', event_map, false

  # Versions, maybe a little more complicated...
  # Essentially, versions have a lot of fields we have to kick over, both at the top level (item_id, whodunnit)
  # and nested (object, object_changes).
  # This is essentially a more complicated version of the lambdas above, except it changes anything that's known to be an id
  # to the new value that's just been inserted into db. End effect is that all the ids stowed in versions change to the new appropriate value.
  @fkey_mappings = {
    'org_id' => {@org_id => @org_id},
    'clinic_id' => @clinic_mappings,
    'last_edited_by_id' => @user_mappings,
    'user_id' => @user_mappings,
    'region_id' => @region_mappings,
    'patient_id' => @patient_mappings,
    'can_call_id' => @patient_mappings,
    'can_fulfill_id' => @patient_mappings,
    'can_support_id' => @patient_mappings
  }
  @item_type_mappings = {
    'ArchivedPatient' => @archived_patient_mappings,
    'Call' => @call_mappings,
    'CallListEntry' => @call_list_entry_mappings,
    'Clinic' => @clinic_mappings,
    'Config' => @config_mappings,
    'Event' => @event_mappings,
    'Fulfillment' => @fulfillment_mappings,
    'Region' => @region_mappings,
    'Note' => @note_mappings,
    'Patient' => @patient_mappings,
    'User' => @user_mappings,
    'PracticalSupport' => @practical_support_mappings,
  }

  def _is_an_obj_key?(key)
    @fkey_mappings.keys.include? key || (key.start_with?('can_') && key.end_with?('_id'))
  end

  def transform_obj(obj, item_type, value_will_be_array)
    obj.each_pair do |k, v|
      # Handle `id` fields
      obj['id'] = @item_type_mappings[item_type][v] if k == 'id'

      # Process the object mappings to handle polymorphic properly
      if _is_an_obj_key? k
        polymorphic_aware_mappings = if k == 'can_call_id'
                                       obj['can_call_type'] == 'Patient' ? @patient_mappings : @archived_patient_mappings
                                     elsif k == 'can_fulfill_id'
                                       obj[k] = obj['can_fulfill_type'] == 'Patient' ? @patient_mappings : @archived_patient_mappings
                                     elsif k == 'can_support_id'
                                       obj[k] = obj['can_support_type'] == 'Patient' ? @patient_mappings : @archived_patient_mappings
                                     else
                                       @fkey_mappings[k]
                                     end

        # handle non-`id` fields with polymorphic-aware mappings
        obj[k] = value_will_be_array ? v.map { |x| polymorphic_aware_mappings[v] } : polymorphic_aware_mappings[v]
      end
    end
    obj
  end

  # Transfer versions, porting keys along the way
  version_map = -> (x) {
    res = x.except('id', 'created_at', 'item_id', 'org_id', 'object', 'object_changes', 'whodunnit')
           .merge({
             'item_id' => @item_type_mappings[x['item_type']][x['item_id']],
             'created_at' => x['created_at'].asctime.in_time_zone("America/New_York"),
             'object' => x['object'].nil? ? nil : transform_obj(JSON.parse(x['object']), x['item_type'], false),
             'object_changes' => x['object_changes'].nil? ? nil : transform_obj(JSON.parse(x['object_changes']), x['item_type'], true),
             'whodunnit' => x['whodunnit'].nil? ? nil : @user_mappings[x['whodunnit'].to_i],
           })
    res['item_id'].nil? ? nil : res
  }
  @version_mappings = easy_mass_insert PaperTrailVersion, 'versions', version_map, false

  puts "Org id #{@org_id} completed #{Time.zone.now}"
end
