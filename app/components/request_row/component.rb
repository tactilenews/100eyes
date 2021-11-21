# frozen_string_literal: true

module RequestRow
  class Component < ApplicationComponent
    def initialize(request:, **)
      super
      @request = request
    end

    private

    attr_reader :request
  end
end
