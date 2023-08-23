# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class << self
      def send!(message)
        business_solution_provider.constantize.send!(message)
      end

      def send_welcome_message!(contributor)
        business_solution_provider.constantize.send_welcome_message!(contributor)
      end

      def send_more_info_message!(contributor)
        business_solution_provider.constantize.send_more_info_message!(contributor)
      end

      def send_unsubsribed_successfully_message!(contributor)
        business_solution_provider.constantize.send_unsubsribed_successfully_message!(contributor)
      end

      private

      def business_solution_provider
        Setting.three_sixty_dialog_client_api_key.present? ? WhatsAppAdapter::ThreeSixtyDialogOutbound : WhatsAppAdapter::TwilioOutbound
      end
    end
  end
end
