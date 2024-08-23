# frozen_string_literal: true

module ChatForm
  class ChatForm < ApplicationComponent
    def initialize(organization:, contributor:, reply_to: nil)
      super

      @organization = organization
      @contributor = contributor
      @reply_to = reply_to
    end

    private

    attr_reader :organization, :contributor, :reply_to

    def prefilled_value
      return nil unless reply_to

      text = reply_to.text.present? ? reply_to.text.truncate(50) : date_time(reply_to.updated_at)

      t('.reply_to_reference', text: text)
    end
  end
end
