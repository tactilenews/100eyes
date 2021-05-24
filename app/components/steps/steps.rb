# frozen_string_literal: true

module Steps
  class Steps < ApplicationComponent
    def initialize(list: nil, **)
      super

      @list = list.to_s
    end

    private

    attr_reader :list
  end
end
