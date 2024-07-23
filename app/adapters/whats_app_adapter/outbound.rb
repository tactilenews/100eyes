# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class << self
      delegate :send!, to: :business_solution_provider

      delegate :send_welcome_message!, to: :business_solution_provider

      delegate :send_more_info_message!, to: :business_solution_provider

      delegate :send_unsubsribed_successfully_message!, to: :business_solution_provider

      delegate :send_resubscribe_error_message!, to: :business_solution_provider

      private

      def business_solution_provider
        if Organization.singleton.three_sixty_dialog_client_api_key.present?
          WhatsAppAdapter::ThreeSixtyDialogOutbound
        else
          WhatsAppAdapter::TwilioOutbound
        end
      end
    end
  end
end
