# frozen_string_literal: true

module OrganizationsField
  class OrganizationsField < ApplicationComponent
    def initialize(type:, attr:, organization:, **)
      super

      @type = type
      @organization = organization
      @attr = attr
    end

    def call
      component('field', object: organization, value: organization.send(attr), attr: attr) do |field|
        component(type, field.input_defaults)
      end
    end

    private

    attr_reader :type, :attr, :organization
  end
end
