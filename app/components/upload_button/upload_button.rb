# frozen_string_literal: true

module UploadButton
  class UploadButton < ApplicationComponent
    def initialize(id:, input_label:, button_label:, **)
      super

      @id = id
      @input_label = input_label
      @button_label = button_label
    end

    private

    attr_reader :id, :input_label, :button_label
  end
end
