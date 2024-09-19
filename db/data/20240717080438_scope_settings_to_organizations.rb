# frozen_string_literal: true

class ScopeSettingsToOrganizations < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.transaction do
      return unless ActiveRecord::Base.connection.table_exists? 'settings'

      organization = Organization.first
      return unless organization

      attrs = Setting.keys
      attrs.each do |setting|
        next unless organization.respond_to?("#{setting}=")

        organization.send("#{setting}=", Setting.send(setting))
        Rails.logger.debug '.'
      end

      Setting.channels.each do |setting_key, _value|
        organization.onboarding_allowed.each do |key, _value|
          next unless setting_key.to_sym.eql?(key.to_sym)

          organization.onboarding_allowed[key] = Setting.channels[setting_key][:allow_onboarding]
        end
      end

      organization.threemarb_api_secret = ENV.fetch('THREEMARB_API_SECRET', nil)
      organization.threemarb_private = ENV.fetch('THREEMARB_PRIVATE', nil)

      organization.onboarding_logo.attach(Setting.onboarding_logo) if Setting.onboarding_logo
      organization.onboarding_hero.attach(Setting.onboarding_hero) if Setting.onboarding_hero
      organization.channel_image.attach(Setting.channel_image) if Setting.channel_image
      organization.save!
    end
  end

  def down
    ActiveRecord::Base.transaction do
      organization = Organization.singleton
      return unless organization

      attrs = Setting.keys
      attrs.each do |setting|
        next unless organization.respond_to?("#{setting}=")

        organization.send("#{setting}=", nil)
        Rails.logger.debug '.'
      end

      organization.onboarding_allowed = { threema: true, telegram: true, email: true, signal: true, whats_app: true }
      organization.threemarb_api_secret = nil
      organization.threemarb_private = nil

      organization.onboarding_logo = nil
      organization.onboarding_hero = nil
      organization.channel_image = nil
      organization.save!
    end
  end
end
