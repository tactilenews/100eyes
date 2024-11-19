# frozen_string_literal: true

class BroadcastRequestJob < ApplicationJob
  queue_as :broadcast_request

  attr_reader :request, :recipients

  def perform(request_id)
    @request = Request.find(request_id)
    return if request.broadcasted_at.present?
    return if request.planned? # rescheduled for future

    all_recipients = request.organization.contributors.active.with_tags(request.tag_list)
    whats_app_recipients = all_recipients.with_whats_app
    @recipients = all_recipients - whats_app_recipients

    create_and_send_messages

    WhatsAppAdapter::BroadcastMessagesJob.perform_later(request_id: request.id)

    request.update(broadcasted_at: Time.current)
  end

  private

  def create_and_send_messages
    recipients.each do |contributor|
      message = Message.new(
        sender: request.user,
        recipient: contributor,
        text: request.personalized_text(contributor),
        request: request,
        broadcasted: true
      )

      message.files = Message::File.attach_files(request.files) if request.files.attached?

      message.save!
      message.send!
    end
  end
end
