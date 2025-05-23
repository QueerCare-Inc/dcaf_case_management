require 'application_system_test_case'

class UpdatePatientInfoTest < ApplicationSystemTestCase
  extend Minitest::OptionalRetry

  before do
    @region = create :region
    @region2 = create :region
    @user = create :user
    @admin = create :user, role: :admin
    @clinic = create :clinic
    @patient = create :patient, region: @region
    create_insurance_config
    create_practical_support_config
    create_language_config
    create_referred_by_config

    log_in_as @user
    visit edit_patient_path @patient
    has_text? 'First and last name' # wait until page loads
  end

  describe 'changing patient dashboard information' do
    describe 'updating name' do
      before do
        fill_in 'First and last name', with: 'Susie Everyteen 2'
        click_away_from_field
        wait_for_ajax
        reload_page_and_click_link 'Patient Information'
      end

      it 'should update name' do
        within :css, '#patient_dashboard' do
          assert has_field?('First and last name', with: 'Susie Everyteen 2')
        end
      end
    end

    describe 'updating procedure date' do
      before do
        fill_in 'Procedure date', with: 5.days.from_now.strftime('%m/%d/%Y')
        click_away_from_field
        wait_for_ajax
        reload_page_and_click_link 'Patient Information'
      end

      it 'should update procedure date' do
        within :css, '#patient_dashboard' do
          assert has_field? 'Procedure date', with: 5.days.from_now.strftime('%Y-%m-%d')
        end
      end
    end

    describe 'updating procedure date counter' do
      before do
        @patient.update procedure_date: 5.days.from_now.strftime('%Y-%m-%d')
        visit edit_patient_path @patient
      end

      it 'should update the procedure date counter' do
        assert has_content? 'Currently: 5w 4d'

        assert has_content? 'Currently: 5w 3d'
      end
    end

    describe 'updating phone number' do
      before do
        fill_in 'Phone number', with: '123-666-8888'
        click_away_from_field
        wait_for_ajax
        reload_page_and_click_link 'Patient Information'
      end

      it 'should update phone' do
        within :css, '#patient_dashboard' do
          assert has_field? 'Phone number', with: '123-666-8888'
        end
      end
    end

    describe 'updating pronouns' do
      before do
        fill_in 'Pronouns', with: 'they/them'
        click_away_from_field
        wait_for_ajax
        reload_page_and_click_link 'Patient Information'
      end

      it 'should update pronouns' do
        within :css, '#patient_dashboard' do
          assert has_field? 'Pronouns', with: 'they/them'
        end
      end
    end
  end

  describe 'changing procedure information' do
    before do
      click_link 'Procedure Information'
      select @clinic.name, from: 'patient_clinic_id'
      fill_in 'Appointment time', with: '4:30PM'
      check 'Referred to clinic'
      check 'Multi-day appointment'

      click_away_from_field
      reload_page_and_click_link 'Procedure Information'
    end

    it 'should alter the procedure information' do
      within :css, '#procedure_information' do
        assert_equal @clinic.id.to_s, find('#patient_clinic_id').value
        assert has_field? 'Appointment time', with: '16:30'
        assert has_checked_field?('Referred to clinic')
        assert has_checked_field?('Multi-day appointment')
      end
    end
  end

  describe 'changing patient information' do
    before do
      click_link 'Patient Information'
      fill_in 'Other contact name', with: 'Susie Everyteen Sr'
      fill_in 'Other phone', with: '123-666-7777'
      fill_in 'Relationship to other contact', with: 'Friend'
      wait_for_ajax

      fill_in 'Age', with: '24'
      select 'White/Caucasian', from: 'patient_race_ethnicity'
      fill_in 'City', with: 'Washington'
      wait_for_ajax

      select 'DC', from: 'patient_state'
      fill_in 'County', with: 'Wash'
      fill_in 'Zipcode', with: '200091002'
      select 'Voicemail OK', from: 'patient_voicemail_preference'
      check 'Textable?'
      wait_for_ajax

      select 'Spanish', from: 'patient_language'
      select 'Part-time', from: 'patient_employment_status'
      select '$30,000-34,999 ($577-672/wk - $2500-2916/mo)',
             from: 'patient_income'
      wait_for_ajax

      select '1', from: 'patient_household_size_adults'
      select '3', from: 'patient_household_size_children'
      select 'Other state Medicaid', from: 'patient_insurance'
      wait_for_ajax

      select 'Other abortion org', from: 'patient_referred_by'
      check 'Homelessness'
      check 'Prison'
      click_away_from_field
      wait_for_ajax

      reload_page_and_click_link 'Patient Information'
    end

    it 'should alter the patient information information' do
      within :css, '#patient_information' do
        assert has_field? 'Other contact name', with: 'Susie Everyteen Sr'
        assert has_field? 'Other phone', with: '123-666-7777'
        assert has_field? 'Relationship to other contact', with: 'Friend'
        assert has_field? 'Age', with: '24'
        assert_equal 'White/Caucasian', find('#patient_race_ethnicity').value
        assert has_field? 'City', with: 'Washington'
        assert_equal 'DC', find('#patient_state').value
        assert has_field? 'County', with: 'Wash'
        assert has_field? 'Zipcode', with: '20009-1002'
        assert_equal 'yes', find('#patient_voicemail_preference').value
        assert has_checked_field?('Textable?')
        assert_equal 'Spanish', find('#patient_language').value

        assert_equal 'Part-time', find('#patient_employment_status').value
        assert_equal '$30,000-34,999',
                     find('#patient_income').value
        assert_equal '1', find('#patient_household_size_adults').value
        assert_equal '3', find('#patient_household_size_children').value
        assert_equal 'Other state Medicaid', find('#patient_insurance').value
        assert_equal 'Other abortion org', find('#patient_referred_by').value
        assert_equal 'yes', find('#patient_voicemail_preference').value
        assert_equal 'Spanish', find('#patient_language').value
        assert has_checked_field? 'Homelessness'
        assert has_checked_field? 'Prison'
        assert has_no_css? '#patient_region'
      end
    end

    describe 'changing ADMIN patient information' do
      before do
        @admin = create :user, role: :admin
        log_out
        log_in_as @admin
        visit edit_patient_path @patient
        wait_for_element 'Patient Information'

        select @region2.name, from: 'patient_region_id'
        click_away_from_field
        reload_page_and_click_link 'Patient Information'
      end

      it 'should alter the information' do
        within :css, '#patient_information' do
          assert_equal @region2.id.to_s, find('#patient_region_id').value
        end
      end
    end
  end

  describe 'flash notifications' do
    it 'should flash success on field change' do
      click_link 'Patient Information'
      fill_in 'Age', with: '25'
      click_away_from_field
      assert has_text? 'Patient info successfully saved'
    end

    it 'should flash failure on a bad field change' do
      fill_in 'Phone number', with: '111-222-3333445'
      click_away_from_field
      assert has_text? 'Primary phone is the wrong length'
    end
  end

  describe 'changing fulfillment information' do
    before do
      @patient = create :patient, procedure_date: 2.days.from_now,
                                  clinic: @clinic

      log_out
      log_in_as @admin
      visit edit_patient_path @patient

      click_link 'Pledge Fulfillment'
      fill_in 'Procedure date', with: 2.days.from_now.strftime('%m/%d/%Y')
      wait_for_ajax

      wait_for_ajax

      fill_in 'Check #', with: '444-22'
      fill_in 'Date of check', with: 2.weeks.from_now.strftime('%m/%d/%Y')

      click_away_from_field
      wait_for_ajax

      check 'Fulfillment audited?'
      wait_for_ajax

      reload_page_and_click_link 'Pledge Fulfillment'
    end

    # PROBLEMATIC TEST
    it 'should alter the information' do
      within :css, '#pledge_fulfillment' do
        assert has_checked_field? 'Pledge fulfilled'
        assert has_field? 'Procedure date',
                          with: 2.days.from_now.strftime('%Y-%m-%d')
        assert has_field? 'Check #', with: '444-22'
        assert has_checked_field? 'Fulfillment audited?'

        # There is something deeply, deeply weird about how capybara enters dates.
        # assert has_field? 'Date of check',
        #                   with: 2.weeks.from_now.strftime('%Y-%m-%d')
      end
    end
  end

  describe 'clicking around' do
    it 'should let you click back to procedure information' do
      click_link 'Notes'
      within(:css, '#sections') { assert_not has_text? 'Procedure information' }
      click_link 'Procedure Information'
      within(:css, '#sections') { assert has_text? 'Procedure information' }
    end
  end

  private

  def reload_page_and_click_link(link_text)
    click_away_from_field
    visit authenticated_root_path
    visit edit_patient_path @patient
    click_link link_text
  end
end
