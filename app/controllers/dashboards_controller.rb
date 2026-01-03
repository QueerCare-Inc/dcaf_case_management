# Controller for rendering the home view and patient search.
class DashboardsController < ApplicationController
  include RegionsHelper

  before_action :pick_region_if_not_set, only: [:index, :search]

  def index
    @shared_patients = eager_loaded_patients.shared_patients(current_region)
    @care_coordinator_users = load_care_coordinator_users
    # @unconfirmed_support_patients = eager_loaded_patients.unconfirmed_practical_support(current_region)
  end

  def search
    @results = if params[:search].present?
                 eager_loaded_patients.search params[:search],
                                              regions: [current_region || Region.all],
                                              person_subtype: Patient
               else
                 []
               end

    @patient = Patient.new
    @person = Person.new
    @today = Time.zone.today.to_date
    @phone_number = searched_for_phone?(params[:search]) ? params[:search] : ''
    @name = searched_for_name?(params[:search]) ? params[:search] : ''

    @new_patient_form = NewPatientForm.new
    @email = ''
    @procecure_date = Time.zone.tomorrow.to_date
    @procedure_type = Procedure.procedure_types[:not_specified]

    respond_to { |format| format.js }
  end

  def week
    @date = params[:date].to_date
    @view = params[:view] || 'month'
    # debugger
    # @shifts = Shift.where(start_time: @date.beginning_of_week..@date.end_of_week)
    # Fetch all shifts and filter them manually
    @shifts = if @view == 'week'
                Shift.all.select do |shift|
                  DateTime.parse(shift.start_time) >= @date.beginning_of_week &&
                    DateTime.parse(shift.start_time) <= @date.end_of_week
                end
              else
                current_user.get_associated_shifts
              end

    # # Initialize the week calendar
    # calendar = SimpleCalendar::WeekCalendar.new(self, date: @date, events: @shifts)

    # date_range = @date.beginning_of_week..@date.end_of_week

    # render partial: 'simple_calendar/week_calendar', locals: {
    #   calendar: calendar,
    #   date_range: date_range.to_a,
    #   passed_block: lambda { |day, shifts|
    #     render_shifts(day, shifts)
    #   }
    # }
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def eager_loaded_patients
    Patient.includes([]) # :calls, :fulfillment
  end

  def searched_for_phone?(query)
    !/[a-z]/i.match query
  end

  def searched_for_name?(query)
    /[a-z]/i.match query
  end

  def pick_region_if_not_set
    redirect_to new_region_path if session[:region_id].blank?
  end

  def load_care_coordinator_users
    @care_coordinator_users = User.where(role: 'care_coordinator')
  end
end
