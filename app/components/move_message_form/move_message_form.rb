# frozen_string_literal: true

module MoveMessageForm
  class MoveMessageForm < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    private

    attr_reader :message

    def request
      @message.request
    end

    def recent_requests
      Request
        .where('broadcasted_at <= ?', request.broadcasted_at)
        .order(broadcasted_at: :desc)
        .limit(5)
    end

    def choices
      recent_requests.map do |request|
        {
          value: request.id,
          label: request.title,
          help: "Frage gestellt #{date_time(request.broadcasted_at)}"
        }
      end
    end

    def cancel_link
      request_url(request, anchor: "message-#{message.id}")
    end
  end
end
