# frozen_string_literal: true

class OrganizationComponent < ApplicationComponent
  def initialize(organization:, **)
    @organization = organization

    super
  end

  attr_reader :organization
end
