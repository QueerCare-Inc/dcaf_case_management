require 'test_helper'

class OrgTest < ActiveSupport::TestCase
  before do
    @org = Org.first # created during setup
  end

  describe 'basic validations' do
    it 'should build' do
      assert create(:org).valid?
    end

    [:name, :subdomain, :domain, :full_name].each do |attrib|
      it "should require #{attrib}" do
        @org[attrib] = nil
        assert_not @org.valid?
      end
    end

    [:name, :subdomain].each do |attrib|
      it "should be unique on #{attrib}" do
        nonunique_org = create :org
        nonunique_org[attrib] = @org[attrib]
        assert_not nonunique_org.valid?
      end
    end
  end

  describe 'scoping by org' do
    before { @org2 = create :org }

    it 'should separate objects by org' do
      [@org, @org2].each do |org|
        ActsAsTenant.with_tenant(org) do
          create :patient
        end
      end

      # The orgs should see only one of them
      ActsAsTenant.with_tenant(@org) do
        assert_equal 1, Patient.count
        @pt1 = Patient.first
      end
      ActsAsTenant.with_tenant(@org2) do
        assert_equal 1, Patient.count
        @pt2 = Patient.first
      end
      assert_not_equal @pt1.id, @pt2.id
      assert_not_equal @pt1.org_id, @pt2.org_id

      # But there should be two patients in db
      ActsAsTenant.current_tenant = nil
      ActsAsTenant.test_tenant = nil
      assert_equal 2, Patient.count
    end

    it 'should be able to delete its patient-related data without affecting other orgs' do
      [@org, @org2].each do |org|
        ActsAsTenant.with_tenant(org) do
          @patient = create :patient
          @patient.notes.create attributes_for(:note)
          @patient.calls.create attributes_for(:call)
          @patient.practical_supports.create attributes_for(:practical_support)
          @archived_patient = create :archived_patient
          @archived_patient.calls.create attributes_for(:call)
          @archived_patient.practical_supports.create attributes_for(:practical_support)
        end
      end

      @org.delete_patient_related_data

      ActsAsTenant.with_tenant(@org) do
        [Patient,
         ArchivedPatient,
         Note,
         Fulfillment,
         PracticalSupport,
         Call].each do |model|
          assert_equal 0, model.count
        end
      end

      ActsAsTenant.with_tenant(@org2) do
        [Patient,
         ArchivedPatient,
         Note,
         Fulfillment].each do |model|
          assert_equal 1, model.count
        end
        [
          PracticalSupport,
          Call
        ].each do |model|
          assert_equal 2, model.count
        end
      end
    end

    it 'should be able to delete its administrative-related data without affecting other orgs' do
      [@org, @org2].each do |org|
        ActsAsTenant.with_tenant(org) do
          create :user
          create :config
          create :region
          create :clinic
        end
      end

      @org.delete_administrative_data

      ActsAsTenant.with_tenant(@org) do
        [Clinic, Config, Region, User].each do |model|
          assert_equal 0, model.count
        end
      end

      ActsAsTenant.with_tenant(@org2) do
        [Clinic, Config, Region, User].each do |model|
          assert_equal 1, model.count
        end
      end
    end
  end
end
