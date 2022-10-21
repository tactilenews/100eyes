# frozen_string_literal: true

class ChartsController < ApplicationController
  def time_based_activity
    grouped_requests = Request.unscoped.group_by_hour_of_day(:created_at, format: '%H:%M').count
    grouped_outbound_messages = Message.unscoped.where(sender_type: [User.name, nil], broadcasted: false).group_by_hour_of_day(:created_at, format: '%H:%M').count
    joined_outbound = grouped_requests.merge(grouped_outbound_messages) { |_key, oldval, newval| oldval + newval }
    render json: [{ 
      name: 'Eingegangene', data: Message.unscoped.replies.group_by_hour_of_day(:created_at, format: '%H:%M').count },
      { name: 'Fragen', data: joined_outbound }]
  end
end
