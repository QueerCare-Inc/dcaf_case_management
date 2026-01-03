# Methods related to displaying attributes on the patient model
module DateDisplayable
  extend ActiveSupport::Concern

  def display_date
    strftime('%m/%d/%Y')
  end
end
