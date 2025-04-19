desc 'Run nightly cleanup methods on call lists, users, patients, etc.'
task nightly_cleanup: :environment do
  # Run most of these tasks nightly
  Rake::Task['db:sessions:trim'].invoke
  puts "#{Time.now} -- removed old sessions"

  Event.destroy_old_events
  puts "#{Time.now} -- destroyed old events"

  PaperTrailVersion.destroy_old
  puts "#{Time.now} -- destroyed old audit objects"

  if Time.zone.now.monday?
    # Run these events weekly
    Clinic.update_all_coordinates
    puts "#{Time.now} -- refreshed coordinates on all clinics"
  end

  Org.all.each do |org|
    ActsAsTenant.with_tenant(org) do
      User.all.each { |user| user.clean_call_list_between_shifts }
      puts "#{Time.now} -- cleared all recently reached patients from call lists for org #{org.name}"

      User.disable_inactive_users
      puts "#{Time.now} -- locked accounts of users who have not logged in since #{User::TIME_BEFORE_DISABLED_BY_ORG.ago} for org #{org.name}"

      Patient.trim_shared_patients
      puts "#{Time.now} -- trimmed shared patients for org #{org.name}"

      ArchivedPatient.archive_eligible_patients!
      puts "#{Time.now} -- archived patients for today for org #{org.name}"
    end
  end
end
