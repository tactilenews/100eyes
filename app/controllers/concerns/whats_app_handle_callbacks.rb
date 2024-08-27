# frozen_string_literal: true

module WhatsAppHandleCallbacks
  extend ActiveSupport::Concern

  private

  def handle_unknown_contributor(whats_app_phone_number)
    exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
    ErrorNotifier.report(exception)
  end
end
