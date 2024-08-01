# frozen_string_literal: true

class OrganizationComponent < ApplicationComponent
  delegate :organization, to: :helpers
end
