# For render
class EventsController < ApplicationController
  include RegionsHelper

  def index
    events = Event.where(region: current_region)
                  .order(created_at: :desc)

    @events = paginate_results(events)
    respond_to do |format|
      format.html { render partial: 'events/events' }
      format.js { render layout: false }
    end
  end

  private

  def paginate_results(results)
    Kaminari.paginate_array(results)
            .page(params[:page])
            .per(25)
  end
end
