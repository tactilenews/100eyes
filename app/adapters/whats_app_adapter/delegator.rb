# frozen_string_literal: true

module WhatsAppAdapter
  class Delegator
    def initialize(organization)
      @business_solution_provider = if organization.three_sixty_dialog_client_api_key.present?
                                      WhatsAppAdapter::ThreeSixtyDialogOutbound
                                    else
                                      WhatsAppAdapter::TwilioOutbound
                                    end
    end

    attr_reader :business_solution_provider

    delegate :send!, to: :business_solution_provider

    delegate :send_welcome_message!, to: :business_solution_provider

    delegate :send_more_info_message!, to: :business_solution_provider

    delegate :send_unsubsribed_successfully_message!, to: :business_solution_provider

    delegate :send_resubscribe_error_message!, to: :business_solution_provider
  end
end
