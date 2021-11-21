# frozen_string_literal: true

module Onboarding
  module Hero
    class Component < ApplicationComponent
      def initialize(image:, **)
        super

        @image = image
      end

      private

      attr_reader :image
    end
  end
end
