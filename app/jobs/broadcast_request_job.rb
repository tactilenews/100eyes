# frozen_string_literal: true

# frozen_string_literal

class BroadcastRequestJob < ApplicationJob
  queue_as :broadcast_request

  def perform(request_id)
    request = Request.find(request_id)
    if request.schedule_send_for.present? && request.schedule_send_for > Time.current
      BroadcastRequestJob.delay(run_at: request.schedule_send_for).perform_later(request.id)
      return
    end

    Contributor.active.with_tags(request.tag_list).each do |contributor|
      message = Message.new(
        sender: request.user,
        recipient: contributor,
        text: request.personalized_text(contributor),
        request: request,
        broadcasted: true
      )
      message.files = Request.attach_files(request.files) if request.files.attached?
      message.save!
    end
  end
end
