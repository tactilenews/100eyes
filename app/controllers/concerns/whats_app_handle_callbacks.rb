# frozen_string_literal: true

module WhatsAppHandleCallbacks
  extend ActiveSupport::Concern

  private

  def handle_unknown_contributor(whats_app_phone_number)
    exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
    ErrorNotifier.report(exception)
  end

  def handle_request_for_more_info(contributor)
    contributor.update!(whats_app_message_template_responded_at: Time.current)

    WhatsAppAdapter::Outbound.send_more_info_message!(contributor)
  end

  def handle_subscribe_contributor(contributor)
    contributor.update!(unsubscribed_at: nil, whats_app_message_template_responded_at: Time.current)

    WhatsAppAdapter::Outbound.send_welcome_message!(contributor)
    ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
    end
  end
end
