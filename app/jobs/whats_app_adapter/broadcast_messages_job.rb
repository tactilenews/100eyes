# frozen_string_literal: true

module WhatsAppAdapter
  class BroadcastMessagesJob < ApplicationJob
    queue_as :broadcast_whats_app_messages

    attr_reader :request, :recipients

    def perform(request_id: request.id)
      @request = Request.find(request_id)
      @recipients = request.organization.contributors.active.with_tags(request.tag_list).with_whats_app

      upload_files_to_meta if request.files.attached?
      create_and_send_messages
    end

    private

    def upload_files_to_meta
      WhatsAppAdapter::ThreeSixtyDialog::UploadFileService.call(request_id: request.id)
    end

    def create_and_send_messages
      recipients.each do |contributor|
        message = Message.new(
          sender: request.user,
          recipient: contributor,
          text: request.personalized_text(contributor),
          request: request,
          organization: request.organization,
          broadcasted: true
        )

        message.files = Message::File.attach_files(request.files) if request.files.attached?

        message.save!
        message.send!
      end
    end
  end
end
