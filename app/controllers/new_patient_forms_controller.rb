class NewPatientFormsController < ApplicationController
  def create
    @new_patient_form = NewPatientForm.new(new_patient_params)

    if @new_patient_form.save
      current_user.add_new_patient @new_patient_form

      respond_to do |format|
        format.js do
          render template: 'users/refresh_care_requests',
                 layout: false,
                 locals: {table_type: 'new_care_requests_list'}
        end
      end
    else
      render :new
    end
  end

  def new_patient_params
    params.require(:new_patient_form).permit(
      :primary_phone,
      :name,
      :email,
      :procedure_date,
      :procedure_type,
      :region_id,
      :org_id
    )
  end
end
