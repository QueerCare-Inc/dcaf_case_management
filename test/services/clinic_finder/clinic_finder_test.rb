require 'test_helper'

# Test initialization and top level methods.
class ClinicFinderTest < ActiveSupport::TestCase
  before do
    # These fixtures are CA in honor of the Abortion Access Hackathon SF team
    # who originally constructed the clinic finder code, and who are wonderful
    create :clinic, name: 'PP Oakland',
                    street_address: '1001 Broadway',
                    city: 'Oakland',
                    state: 'CA',
                    zip: '94607',
                    accepts_medicaid: false
    create :clinic, name: 'PP SF',
                    street_address: '2430 Folsom',
                    city: 'San Francisco',
                    state: 'CA',
                    zip: '94110',
                    accepts_medicaid: false
    create :clinic, name: 'Out of state clinic',
                    street_address: '1801 Mountain NW',
                    city: 'Albuquerque',
                    state: 'NM',
                    zip: '87104',
                    accepts_medicaid: true
    create :clinic, name: 'Monterey Clinic',
                    street_address: '570 Pacific',
                    city: 'Monterey',
                    state: 'CA',
                    zip: '93940',
                    accepts_medicaid: false
  end

  describe 'initialization with clinics' do
    before do
      @clinics = Clinic.all
      @abortron = ClinicFinder::Locator.new Clinic.all
    end

    it 'should initialize with clinics' do
      assert(@abortron.clinic_structs.find { |c| c.name == 'PP SF' })
      assert_equal Clinic.all.count, @abortron.clinic_structs.count
    end

    it 'should have mirroring clinic and clinic_structs on init' do
      @abortron.clinic_structs.each do |clinic_struct|
        clinic = @clinics.find clinic_struct.id
        clinic.attributes.each_pair do |k, _v|
          attr_value = clinic.instance_variable_get("@#{k}")
          assert_equal attr_value, clinic_struct[k] if attr_value
        end
      end
    end

    it 'should make a patient context obj available' do
      assert @abortron.respond_to? :patient_context
      @abortron.patient_context.yolo = 'goat'
      assert_equal 'goat', @abortron.patient_context.yolo
    end
  end
end
