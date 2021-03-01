# frozen_string_literal: true

module MessageForm
  class MessageForm < ApplicationComponent
    def initialize(contributor:, request:, **)
      super

      @contributor = contributor
      @request = request
    end

    private

    attr_reader :contributor, :request
  end
end
