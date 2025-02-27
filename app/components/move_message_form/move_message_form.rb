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
      message.organization.requests
             .where('broadcasted_at <= ?', message.created_at)
             .order(broadcasted_at: :desc)
             .limit(5)
    end

    def choices
      choices_array = recent_requests.map do |request|
        {
          value: request.id,
          label: request.title,
          help: "Frage gestellt #{date_time(request.broadcasted_at)}"
        }
      end
      choices_array.push({ label: t('.no_request.label'), help: t('.no_request.help') })
    end

    def cancel_link
      if request.present?
        organization_request_url(request.organization_id, request, anchor: "message-#{message.id}")
      elsif reply?
        conversations_organization_contributor_url(message.organization_id, message.sender.id)
      else
        conversations_organization_contributor_url(message.organization_id, message.contributor.id)
      end
    end
  end
end
