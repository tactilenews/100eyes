# frozen_string_literal: true

module WhatsApp
  class OnboardingController < ApplicationController
    def success
      Rails.logger.debug params
      channel_ids = params[:channels].split('[').last.split(']').last.split(',')
      channel_ids.each do |channel_id|
        WhatsAppAdapter::CreateApiKey.perform_later(channel_id: channel_id)
      end
    end
  end
end
