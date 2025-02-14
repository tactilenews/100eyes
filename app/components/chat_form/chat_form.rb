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
  end
end
