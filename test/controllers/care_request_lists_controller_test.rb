require 'test_helper'

class CareRequestListsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user, role: 'admin'
    @user_2 = create :user, role: 'care_coordinator', name: 'Billy Everyteen'
    @region = create :region

    @user_patient1 = create :user,
                            role: :cr,
                            name: 'Susie Everyteen',
                            primary_phone: '123-456-7890',
                            email: 'susie@example.com'
    @person1 = create :person, user_id: @user_patient1.id
    @patient_1 = create :patient,
                        person_id: @person1.id
    @procedure_1 = create :procedure,
                          region_id: @region.id,
                          person_id: @person1.id,
                          patient_id: @patient_1.id,
                          procedure_date: Time.now + rand(10).days
                          procedure_type: 'other'

    @user_patient2 = create :user,
                            role: :cr,
                            name: 'Yolo Goat',
                            primary_phone: '123-456-7891',
                            email: 'yolo@example.com'
    @person2 = create :person, user_id: @user_patient2.id
    @patient_2 = create :patient,
                        person_id: @person2.id
    @procedure_2 = create :procedure,
                          region_id: @region.id,
                          person_id: @person2.id,
                          patient_id: @patient_2.id,
                          procedure_date: Time.now + rand(10).days
                          procedure_type: 'other'              

    sign_in @user
    choose_region @region
  end

  describe 'add_care_request method' do
    before do
      patch add_care_request_path(@procedure_1), xhr: true
    end

    it 'should respond successfully' do
      assert_response :success
    end

    # ToDo: replace with appropriate care coordinatable objects
    # it 'should add a procedure to a users list' do
    #   @user.reload
    #   assert_equal @user.care_request_list_entries.count, 1
    #   assert_difference '@user.care_request_list_entries.count', 1 do
    #     patch add_care_request_path(@procedure_2), xhr: true
    #     @user.reload
    #   end
    #   assert_equal @user.care_request_list_entries.count, 2
    # end

    # ToDo: replace with appropriate care coordinatable objects
    # it 'should not adjust the count if a procedure is already in the list' do
    #   assert_no_difference '@user.care_request_list_entries.count' do
    #     patch add_care_request_path(@procedure_1), xhr: true
    #   end
    # end

    it 'should should return not found on sketch ids' do
      patch add_care_request_path('noprocedure'), xhr: true
      assert_response :not_found
    end
  end

  describe 'remove_care_request method' do
    before do
      patch add_care_request_path(@procedure_1), xhr: true
      patch add_care_request_path(@procedure_2), xhr: true
      patch remove_care_request_path(@procedure_1), xhr: true
      @user.reload
    end

    it 'should respond successfully' do
      assert_response :success
    end

    # ToDo: replace with appropriate care coordinatable objects
    # it 'should remove a procedure' do
    #   assert_difference '@user.care_request_list_entries.count', -1 do
    #     patch remove_care_request_path(@procedure_2), xhr: true
    #     @user.reload
    #   end
    # end

    # ToDo: replace with appropriate care coordinatable objects
    # it 'should do nothing if the procedure is not currently in the care_request list' do
    #   assert_no_difference '@user.care_request_list_entries.count' do
    #     patch remove_care_request_path(@procedure_1), xhr: true
    #   end
    #   assert_response :not_found
    # end

    it 'should should return bad request on sketch ids' do
      patch remove_care_request_path('whatever'), xhr: true
      assert_response :not_found
    end
  end

  # ToDo: replace with appropriate care coordinatable objects
  # describe 'clear_current_user_care_request_list method' do
  #   before do
  #     patch add_care_request_path(@procedure_1), xhr: true
  #     patch add_care_request_path(@procedure_2), xhr: true
  #     @user.reload
  #   end

  #   it 'should respond successfully' do
  #     patch clear_current_user_care_request_list_path, xhr: true
  #     assert_response :success
  #   end

  #   it 'should clear all care_request lists for a user' do
  #     assert_difference '@user.care_request_list_entries.count', -2 do
  #       patch clear_current_user_care_request_list_path, xhr: true
  #       @user.reload
  #     end
  #   end

  #   it 'should not destroy procedures' do
  #     assert_no_difference 'Procedure.count' do
  #       patch clear_current_user_care_request_list_path, xhr: true
  #     end
  #   end
  # end

  # ToDo: replace with appropriate care coordinatable objects
  # describe 'reorder care_request list' do
  #   before do
  #     @ids = []
  #     4.times do
  #       pt = create :procedure, region: @region
  #       @ids << pt.id.to_s
  #       @user.add_care_request pt
  #     end
  #     @ids.shuffle!

  #     patch reorder_care_request_list_path, params: { order: @ids },
  #                                   xhr: true
  #     @user.reload
  #   end

  #   it 'should respond success' do
  #     assert_response :success
  #   end

  #   it 'should rerack order keys' do
  #     assert_not_nil @user.care_request_list_entries
  #     assert_equal @user.care_request_list_patients(@region).map { |x| x.id.to_s }, @ids
  #   end
  # end
end
