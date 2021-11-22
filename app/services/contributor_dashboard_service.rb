# frozen_string_literal: true

class ContributorDashboardService < ApplicationService
  def initialize(params)
    super()
    @params = params
  end

  def call
    contributors = Contributor.unscoped.includes(:most_recent_reply)
    contributors = filter_param == :inactive ? contributors.inactive : contributors.active

    order_mapping = {
      name: %i[first_name last_name],
      activity: ['messages.created_at']
    }
    order_direction_mapping = {
      desc: 'DESC NULLS LAST',
      asc: 'ASC NULLS FIRST'
    }

    order_clause = order_mapping[order_param]
                   .map { |clause| "#{clause} #{order_direction_mapping[order_direction_param]}" }
                   .join(', ')
    Rails.logger.debug { "---------------- #{order_clause} -----------------------" }
    contributors = contributors.with_attached_avatar.includes(:tags)
    contributors.order(order_clause)
  end

  private

  def filter_param
    value = @params.permit(:filter)[:filter]&.to_sym

    return :active unless %i[active inactive].include?(value)

    value
  end

  def order_param
    value = @params.permit(:order)[:order]&.to_sym

    return :name unless %i[name activity].include?(value)

    value
  end

  def order_direction_param
    value = @params.permit(:order_direction)[:order_direction]&.to_sym

    return :asc unless %i[asc desc].include?(value)

    value
  end
end
