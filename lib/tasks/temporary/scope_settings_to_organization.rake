# frozen_string_literal: true

namespace :organizations do
  desc 'Migrate global settings to organization scope'
  task scope_settings_to_organization: :environment do
    ActiveRecord::Base.transaction do
      organization = Organization.first
      return unless organization

      attrs = Setting.keys
      attrs.each do |setting|
        next unless organization.respond_to?(setting)

        organization.send("#{setting}=", Setting.send(setting))
        organization.save!
        print '.'
      end

      organization.onboarding_logo.attach(Setting.onboarding_logo) if Setting.onboarding_logo
      organization.onboarding_hero.attach(Setting.onboarding_hero) if Setting.onboarding_hero
      organization.channel_image.attach(Setting.channel_image) if Setting.channel_image
      organization.update!(threemarb_api_secret: ENV.fetch('THREEMARB_API_SECRET', nil),
                           threemarb_private: ENV.fetch('THREEMARB_PRIVATE', nil))
    end
  end
end
