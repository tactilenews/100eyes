# frozen_string_literal: true

module Hero
  # FIXME: this component seems to be unused
  class Hero < ApplicationComponent
    def initialize(organization_id:, **)
      @organization_id = organization_id
      super
    end
    attr_reader :organization_id
  end
end
