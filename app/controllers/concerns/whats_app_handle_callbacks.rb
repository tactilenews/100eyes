# frozen_string_literal: true

module WhatsAppHandleCallbacks
  extend ActiveSupport::Concern

  private

  def handle_unknown_contributor(whats_app_phone_number)
    exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
    ErrorNotifier.report(exception)
  end

  def handle_request_for_more_info(contributor, organization)
    contributor.update!(whats_app_message_template_responded_at: Time.current)

    WhatsAppAdapter::Outbound.send_more_info_message!(contributor, organization)
  end
end
