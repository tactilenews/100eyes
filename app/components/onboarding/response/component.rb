# frozen_string_literal: true

module Onboarding
  module Response
    class Component < ApplicationComponent
      def initialize(heading:, text:, **)
        super

        @heading = heading
        @text = text

        @styles = [:error] if @styles.empty?
      end

      private

      def icon
        return 'f-check' if styles.include?(:success)

        'd-remove'
      end

      attr_reader :heading, :text
    end
  end
end
