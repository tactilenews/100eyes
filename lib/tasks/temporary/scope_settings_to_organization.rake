# frozen_string_literal: true

namespace :organizations do
  desc 'Migrate global settings to organization scope'
  task scope_settings_to_organization: :environment do
    ActiveRecord::Base.transaction do
      organization = Organization.first
      return unless organization

      Setting.each_key do |setting|
        next unless organization.respond_to?(setting)

        organization.send("#{setting}=", Setting.send(setting))
        organization.save!
        print '.'
      end
    end
  end
end
