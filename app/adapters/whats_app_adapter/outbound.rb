# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class << self
      def send!(message)
        "WhatsAppAdapter::#{business_solution_provider}Outbound".constantize.send!(message)
      end

      def send_welcome_message!(contributor)
        "WhatsAppAdapter::#{business_solution_provider}Outbound".constantize.send_welcome_message!(contributor)
      end

      def send_more_info_message!(contributor)
        "WhatsAppAdapter::#{business_solution_provider}Outbound".constantize.send_more_info_message!(contributor)
      end

      def send_unsubsribed_successfully_message!(contributor)
        "WhatsAppAdapter::#{business_solution_provider}Outbound".constantize.send_unsubsribed_successfully_message!(contributor)
      end

      private

      def business_solution_provider
        Setting.three_sixty_dialog_client_api_key.present? ? 'ThreeSixtyDialog' : 'Twilio'
      end
    end
  end
end
