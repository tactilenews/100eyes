# frozen_string_literal: true

module Notice
  class Notice < ViewComponent::Base
    include ComponentHelper

    def initialize(notice:)
      @notice = notice
    end

    private

    attr_reader :notice
  end
end
