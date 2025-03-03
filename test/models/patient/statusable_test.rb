require 'test_helper'
require_relative '../patient_test'

class PatientTest::Statusable < PatientTest
  describe 'status concern methods' do
    before do
      @user = create :user
      @patient = create :patient, emergency_contact_phone: '111-222-3333',
                                  emergency_contact: 'Yolo'
    end

    describe 'status method branch 1' do
      it 'should default to "No Contact Made" when a patient has no calls' do
        assert_equal Patient::STATUSES[:no_contact][:key], @patient.status
      end

      it 'should default to "No Contact Made" on a patient left voicemail' do
        @patient.calls.create attributes_for(:call, status: :left_voicemail)
        assert_equal Patient::STATUSES[:no_contact][:key], @patient.status
      end

      it 'should still say "No Contact Made" if patient leaves voicemail with appointment' do
        @patient.procedure_date = '01/01/2017'
        assert_equal Patient::STATUSES[:no_contact][:key], @patient.status
      end
    end

    describe 'status method branch 2' do
      it 'should update to "Needs Appointment" once patient has been reached' do
        @patient.calls.create attributes_for(:call, status: :reached_patient)
        assert_equal Patient::STATUSES[:needs_appt][:key], @patient.status
      end

      it 'should update to "Fundraising" once appointment made and patient reached' do
        @patient.calls.create attributes_for(:call, status: :reached_patient)
        @patient.procedure_date = '01/01/2017'
        assert_equal Patient::STATUSES[:fundraising][:key], @patient.status
      end

      it 'should update to "Pledge Fulfilled" if a pledge has been fulfilled' do
        @patient.fulfillment.fulfilled = true
        assert_equal Patient::STATUSES[:fulfilled][:key], @patient.status
      end

      # it 'should update to "Pledge Paid" after a pledge has been paid' do
      # end
      it 'should update to "No contact in 120 days" after 120ish days of no calls' do
        @patient.calls.create attributes_for(:call, status: :reached_patient, created_at: 121.days.ago)
        assert_equal Patient::STATUSES[:dropoff][:key], @patient.status

        @patient.calls.create attributes_for(:call, status: :reached_patient, created_at: 120.days.ago)
        assert_equal Patient::STATUSES[:needs_appt][:key], @patient.status
      end
    end

    describe 'contact_made? method' do
      it 'should return false if no calls have been made' do
        assert_not @patient.send :contact_made?
      end

      it 'should return false if an unsuccessful call has been made' do
        @patient.calls.create attributes_for(:call, status: :left_voicemail)
        assert_not @patient.send :contact_made?
      end

      it 'should return true if a successful call has been made' do
        @patient.calls.create attributes_for(:call, status: :reached_patient)
        assert @patient.send :contact_made?
      end
    end
  end
end
