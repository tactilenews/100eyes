# frozen_string_literal: true

module UploadButton
  class Component < ApplicationComponent
    def initialize(id:, label:, **)
      super

      @id = id
      @label = label
    end

    private

    attr_reader :id, :label
  end
end
