# frozen_string_literal: true

module MoveMessageForm
  class Component < ApplicationComponent
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
        .where('created_at <= ?', request.created_at)
        .order(created_at: :desc)
        .limit(5)
    end

    def choices
      recent_requests.map do |request|
        {
          value: request.id,
          label: request.title,
          help: "Frage gestellt #{date_time(request.created_at)}"
        }
      end
    end

    def cancel_link
      request_url(request, anchor: "message-#{message.id}")
    end
  end
end
