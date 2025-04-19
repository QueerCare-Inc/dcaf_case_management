namespace :org_management do
  desc "Remove a org and all its related objects"
  task :delete_org, [:org_name] => [:environment] do |task, args|
    # query our org
    org_name = args.org_name
    defunct_org = Org.find_by(name: org_name)
    if defunct_org.nil?
      raise 'Org not found. Please doublecheck the name!'
    end
    puts "Removing the org #{org_name} and all its subobjects"
    puts
    puts "Initial model counts by org"
    print_counts

    ActsAsTenant.with_tenant(defunct_org) do
      print "Deleting Patient & Patient-related data"
      defunct_org.delete_patient_related_data
      puts " ✅"

      print "Deleting Org administrative data"
      defunct_org.delete_administrative_data
      puts " ✅"
    end

    # delete the versions & print count deleted
    print "Deleting org PaperTrails"
    PaperTrail::Version.where_object(org_id: defunct_org.id).destroy_all
    PaperTrailVersion.where_object_changes(org_id: defunct_org.id).destroy_all
    puts " ✅"
    puts

    puts "Final model counts by org"
    print_counts

    print "Deleting #{org_name} from the Org table"
    # print the final state
    defunct_org.destroy
    puts " ✅"
  end

  private
  def print_counts
    models_org_agnostic = [ Org, ActiveRecord::SessionStore::Session, PaperTrail::Version, PaperTrailVersion]
    models_org_dependent = [ ArchivedPatient, Patient, Fulfillment, PracticalSupport, Note, Call, Event, CallListEntry, Clinic, Region, Config, User ]
    starting_counts = {}
    Org.all.sort.each do |org|
      org_counts = {}
      models_org_dependent.each do |model|
        org_counts[model.to_s] = model.where(org_id: org.id).size
      end
      starting_counts[org.name] = org_counts
    end
    pp starting_counts

    counts = {}
    models_org_agnostic.each do |model|
      counts[model.to_s] = model.all.size
    end
    puts "Org agnostic model counts"
    pp counts
    puts
  end
end
