require 'test_helper'

class PeopleHelperTest < ActionView::TestCase
  %w[race_ethnicity employment_status insurance income referred_by
     household_size].each do |array|
    describe "#{array}_options" do
      it "should be a usable array - #{array}_options" do
        options_array = send("#{array}_options".to_sym)
        assert options_array.class == Array
        assert options_array.count > 1
      end
    end
  end

  describe 'state options' do
    it 'should return all states and current value' do
      expected_state_array = [[nil, nil],
                              %w[AL AL],
                              %w[AK AK],
                              %w[AZ AZ],
                              %w[AR AR],
                              %w[CA CA],
                              %w[CO CO],
                              %w[CT CT],
                              %w[DE DE],
                              %w[DC DC],
                              %w[FL FL],
                              %w[GA GA],
                              %w[HI HI],
                              %w[ID ID],
                              %w[IL IL],
                              %w[IN IN],
                              %w[IA IA],
                              %w[KS KS],
                              %w[KY KY],
                              %w[LA LA],
                              %w[ME ME],
                              %w[MD MD],
                              %w[MA MA],
                              %w[MI MI],
                              %w[MN MN],
                              %w[MS MS],
                              %w[MO MO],
                              %w[MT MT],
                              %w[NE NE],
                              %w[NV NV],
                              %w[NH NH],
                              %w[NJ NJ],
                              %w[NM NM],
                              %w[NY NY],
                              %w[NC NC],
                              %w[ND ND],
                              %w[OH OH],
                              %w[OK OK],
                              %w[OR OR],
                              %w[PA PA],
                              %w[RI RI],
                              %w[SC SC],
                              %w[SD SD],
                              %w[TN TN],
                              %w[TX TX],
                              %w[UT UT],
                              %w[VT VT],
                              %w[VA VA],
                              %w[WA WA],
                              %w[WV WV],
                              %w[WI WI],
                              %w[WY WY],
                              %w[virginia virginia]]

      assert_same_elements state_options('virginia'), expected_state_array
    end
  end

  describe 'language_options' do
    before { create_language_config }

    it 'should return default languages' do
      expected_lang_options = [
        ['English', nil],
        'Spanish',
        'French',
        'Korean'
      ]
      assert_same_elements expected_lang_options, language_options
    end

    it 'should append extra options' do
      expected_lang_options = [
        ['English', nil],
        'Spanish',
        'French',
        'Korean',
        'Esperanto'
      ]
      assert_same_elements expected_lang_options, language_options('Esperanto')
    end
  end
end
