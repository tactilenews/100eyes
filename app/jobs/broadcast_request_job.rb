# frozen_string_literal: true

class BroadcastRequestJob < ApplicationJob
  queue_as :broadcast_request

  def perform(request_id)
    request = Request.where(id: request_id).first
    return unless request
    return if request.broadcasted_at.present?

    if request.planned? # rescheduled for future after this job was created
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
    request.update(broadcasted_at: Time.current)
  end
end
