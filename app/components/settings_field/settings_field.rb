# frozen_string_literal: true

module SettingsField
  class SettingsField < ApplicationComponent
    def initialize(organization:, type:, attr:, **)
      super

      @organization = organization
      @type = type
      @attr = attr
    end

    def call
      component('field', object: organization, value: organization.send(attr), attr: attr) do |field|
        component(type, field.input_defaults)
      end
    end

    private

    attr_reader :organization, :type, :attr
  end
end
