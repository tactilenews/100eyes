# frozen_string_literal: true

class BroadcastRequestJob < ApplicationJob
  queue_as :broadcast_request

  def perform(request_id)
    request = Request.find(request_id)
    return if request.broadcasted_at.present?
    return if request.planned? # rescheduled for future

    recipients = request.organization.contributors.active.with_tags(request.tag_list)
    WhatsAppAdapter::ThreeSixtyDialog::UploadFileService.call(request_id: request.id) if recipients.with_whats_app.count.positive?

    recipients.each do |contributor|
      message = Message.new(
        sender: request.user,
        recipient: contributor,
        text: request.personalized_text(contributor),
        request: request,
        broadcasted: true
      )

      message.files = Request.attach_files(request.files) if request.files.attached?

      message.save!
      message.send!
    end
    request.update(broadcasted_at: Time.current)
  end
end
