# frozen_string_literal: true

namespace :requests do
  desc 'Check for delayed requests and schedule jobs to send out messages'
  task schedule_delayed_requests: :environment do
    requests = Request.where(schedule_send_for: Time.current.beginning_of_hour..1.hour.from_now)
    requests.each do |request|
      request.messages.each do |message|
        [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound].each do |adapter|
          adapter.send!(message)
        end
      end
    end
  end
end
