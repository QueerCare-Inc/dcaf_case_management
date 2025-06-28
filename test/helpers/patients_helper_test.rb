require 'test_helper'

class PatientsHelperTest < ActionView::TestCase
  describe 'insurance options' do
    describe 'with a config' do
      before { create_insurance_config }

      it 'should include the option set' do
        expected_insurance_options_array = [nil, 'DC Medicaid', 'Other state Medicaid',
                                            ['No insurance', 'No insurance'],
                                            ['Don\'t know', 'Don\'t know'],
                                            ['Prefer not to answer', 'Prefer not to answer'],
                                            ['Other (add to notes)', 'Other (add to notes)']]
        assert_same_elements insurance_options, expected_insurance_options_array
      end

      it 'should append any non-nil passed options to the end' do
        expected_insurance_options_array = [nil, 'DC Medicaid', 'Other state Medicaid',
                                            ['No insurance', 'No insurance'],
                                            ['Don\'t know', 'Don\'t know'],
                                            ['Prefer not to answer', 'Prefer not to answer'],
                                            ['Other (add to notes)', 'Other (add to notes)'],
                                            'Friendship']
        assert_same_elements expected_insurance_options_array,
                             insurance_options('Friendship')
      end

      it 'should not include defaults if configured' do
        create_hide_defaults_config
        assert_same_elements [nil, 'DC Medicaid', 'Other state Medicaid'], insurance_options
      end
    end

    describe 'without a config' do
      before do
        create_hide_defaults_config should_hide: false
      end

      it 'should create a config and return proper options' do
        assert_difference 'Config.count', 1 do
          @options = insurance_options
        end

        expected_insurance_array = [nil,
                                    ['No insurance', 'No insurance'],
                                    ['Don\'t know', 'Don\'t know'],
                                    ['Prefer not to answer', 'Prefer not to answer'],
                                    ['Other (add to notes)', 'Other (add to notes)']]
        assert_same_elements expected_insurance_array, @options
        assert Config.find_by(config_key: 'insurance')
      end
    end
  end

  describe 'referred_by_options' do
    before { create_referred_by_config }

    # base options come from patients_helper
    # Metal band is added by create_referred_by_config
    expected_referrals_base = [
      nil,
      %w[Clinic Clinic],
      ['Crime victim advocacy center', 'Crime victim advocacy center'],
      ['CATF website or social media', 'CATF website or social media'],
      ['Domestic violence crisis/intervention org', 'Domestic violence crisis/intervention org'],
      ['Family member', 'Family member'],
      %w[Friend Friend],
      ['Google/Web search', 'Google/Web search'],
      ['Homeless shelter', 'Homeless shelter'],
      ['Legal clinic', 'Legal clinic'],
      %w[NAF NAF],
      %w[NNAF NNAF],
      ['Other abortion org', 'Other abortion org'],
      ['Previous patient', 'Previous patient'],
      %w[School School],
      ['Sexual assault crisis org', 'Sexual assault crisis org'],
      ['Youth outreach', 'Youth outreach'],
      ['Prefer not to answer', 'Prefer not to answer'],
      'Metal band'
    ]

    it 'should return default referral options' do
      assert_same_elements expected_referrals_base, referred_by_options
    end

    it 'should append extra options' do
      expected_referrals = expected_referrals_base + ['Social Worker']

      assert_same_elements expected_referrals, referred_by_options('Social Worker')
    end

    it 'should not include defaults if configured' do
      create_hide_defaults_config

      assert_same_elements ['Metal band'], referred_by_options
    end
  end
end
