# frozen_string_literal: true

module Avatar
  class Avatar < ViewComponent::Base
    include ComponentHelper

    def initialize(url:)
      @url = url
    end

    private

    attr_reader :url
  end
end
