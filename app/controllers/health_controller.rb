# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate

  def index
    ActiveRecord::Base.connection.execute('select 1')
    ActiveRecord::Migration.check_pending!
  rescue StandardError
    render status: :service_unavailable, json: { status: 'Service Unavailable' }
  else
    render json: { status: 'OK' }
  end
end
