# frozen_string_literal: true

class ChartsController < ApplicationController
  content_security_policy only: :time_based_activity do |policy|
    policy.style_src :self, :unsafe_inline
  end
  
  def time_based_activity
    render json: [{ 
      name: 'Eingegangene', data: Message.unscoped.replies.group_by_day_of_week(:created_at, format: '%A').count },
      { name: 'Fragen', data: Request.unscoped.group_by_day_of_week(:created_at, format: '%A').count }]
  end
end
