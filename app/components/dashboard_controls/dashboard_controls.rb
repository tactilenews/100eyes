# frozen_string_literal: true

module DashboardControls
  class DashboardControls < ApplicationComponent
    def initialize(params:)
      super
      @params = params.dup.permit!
    end

    def order
      I18n.t("components.dashboard_controls.order.#{@params[:order]}")
    end

    def order_direction
      I18n.t("components.dashboard_controls.order_direction.#{@params[:order_direction]}")
    end

    def order_href
      key = @params[:order] == 'name' ? 'activity' : 'name'
      url_for(@params.merge(order: key))
    end

    def order_direction_href
      key = @params[:order_direction] == 'asc' ? 'desc' : 'asc'
      url_for(@params.merge(order_direction: key))
    end
  end
end
