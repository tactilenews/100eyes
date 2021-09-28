# frozen_string_literal: true

module UploadButton
  class UploadButton < ApplicationComponent
    def initialize(id:, label:, **)
      super

      @id = id
      @label = label
    end

    private

    attr_reader :id, :label
  end
end
