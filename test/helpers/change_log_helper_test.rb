require 'test_helper'

class ChangeLogHelperTest < ActionView::TestCase
  describe 'safe_join_fields convenience method' do
    before do
      with_versioning do
        @user_patient = create :user,
                               role: :cr,
                               name: 'Susie Everyteen',
                               primary_phone: '123-456-7890',
                               email: 'susie@example.com'
        @person = create :person, user_id: @user_patient.id
        patient = create :patient,
                         person_id: @person.id,
                         legal_name: 'Old name'

        # patient = create :patient, name: 'Old name'
        patient.update name: 'New name' # , city: 'Canada'
        @changeset = patient.versions.first
      end
    end

    it 'should work' do
      assert_equal safe_join_fields(@changeset.shaped_changes),
                   '<strong>Name:</strong> Old name -&gt; New name<br />' \
                   '<strong>City:</strong> (empty) -&gt; Canada'
    end
  end
end
