# frozen_string_literal: true

module WhatsApp
  module ThreeSixtyDialog
    class SetupController < ApplicationController
      skip_before_action :require_login, :verify_authenticity_token, :user_permitted?
      layout 'minimal'

      def create_api_key
        channel_ids = YAML.safe_load(create_api_key_params[:channels])
        client_id = create_api_key_params[:client]
        @organization.update!(three_sixty_dialog_client_id: client_id)
        channel_ids.each do |channel_id|
          WhatsAppAdapter::CreateApiKey.perform_later(organization_id: @organization.id, channel_id: channel_id)
        end
        render 'whats_app/setup/success'
      end

      private

      def create_api_key_params
        params.permit(:organization_id, :client, :channels, :revoked)
      end
    end
  end
end
