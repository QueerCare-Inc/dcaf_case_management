class ShiftsController < ApplicationController
  before_action :set_shift, only: %i[ show edit update destroy ]

  # GET /shifts
  def index
    @shifts = Shift.all
  end

  # GET /shifts/1
  def show
  end

  # GET /shifts/new
  def new
    @shift = Shift.new
  end

  # GET /shifts/1/edit
  def edit
  end

  # POST /shifts
  def create
    @shift = Shift.new(shift_params)

    if @shift.save
      redirect_to @shift, notice: "Shift was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /shifts/1
  def update
    if @shift.update(shift_params)
      redirect_to @shift, notice: "Shift was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /shifts/1
  def destroy
    @shift.destroy!
    redirect_to shifts_url, notice: "Shift was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shift
      @shift = Shift.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def shift_params
      params.require(:shift).permit(:name, :start_time, :end_time)
    end
end
