# frozen_string_literal: true

module RequestFiles
  class RequestFiles < ApplicationComponent
    def initialize(files:)
      super

      @files = files
    end

    private

    attr_reader :files
  end
end
