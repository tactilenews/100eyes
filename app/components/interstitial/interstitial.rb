# frozen_string_literal: true

module Interstitial
  class Interstitial < ApplicationComponent
    def initialize(size: :xnarrow, **)
      super

      @size = size
    end

    private

    attr_reader :size
  end
end
