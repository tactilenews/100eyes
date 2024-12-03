# frozen_string_literal: true

class Organization < ApplicationRecord
  attr_encrypted_options.merge!(key: Base64.decode64(ENV.fetch('ATTR_ENCRYPTED_KEY', nil)))
  attr_encrypted :threemarb_api_secret, :threemarb_private
  attr_encrypted :twilio_api_key_secret
  attr_encrypted :three_sixty_dialog_client_api_key
  attr_encrypted :telegram_bot_api_key

  belongs_to :business_plan
  belongs_to :contact_person, class_name: 'User', optional: true
  has_many :users_organizations, dependent: :destroy
  has_many :users, through: :users_organizations
  has_many :contributors, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many :messages, through: :requests

  has_one_attached :onboarding_logo
  has_one_attached :onboarding_hero
  has_one_attached :channel_image

  before_update :notify_admin
  after_create_commit :set_telegram_webhook
  after_update_commit :notify_admin_of_welcome_message_change

  phony_normalize :signal_server_phone_number, default_country_code: 'DE'

  validates :telegram_bot_username, uniqueness: true, allow_nil: true
  validates :messengers_about_text, length: { maximum: 139 }, allow_blank: true

  def channels_onboarding_allowed
    {
      email: email_onboarding_allowed?,
      signal: signal_onboarding_allowed?,
      telegram: telegram_onboarding_allowed?,
      threema: threema_onboarding_allowed?,
      whats_app: whats_app_onboarding_allowed?
    }.select { |_k, v| v }.keys
  end

  def onboarding_allowed=(value)
    self[:onboarding_allowed] = value.is_a?(String) ? JSON.parse(value) : value
  end

  def whats_app_quick_reply_button_text=(value)
    self[:whats_app_quick_reply_button_text] = value.is_a?(String) ? JSON.parse(value) : value
  end

  def whats_app_configured?
    twilio_configured? || three_sixty_dialog_configured?
  end

  def twilio_configured?
    whats_app_server_phone_number.present? && twilio_api_key_sid.present? && twilio_api_key_secret.present? && twilio_account_sid.present?
  end

  def three_sixty_dialog_configured?
    three_sixty_dialog_client_api_key.present?
  end

  def telegram_configured?
    telegram_bot_api_key.present?
  end

  def onboarding_allowed?(value)
    onboarding_allowed.with_indifferent_access[value]
  end

  def email_onboarding_allowed?
    ENV.fetch('POSTMARK_API_TOKEN', nil).present? && email_from_address.present? && onboarding_allowed?(:email)
  end

  def signal_onboarding_allowed?
    signal_server_phone_number.present? && onboarding_allowed?(:signal)
  end

  def threema_onboarding_allowed?
    threemarb_api_identity.present? && onboarding_allowed?(:threema)
  end

  def telegram_onboarding_allowed?
    telegram_configured? && onboarding_allowed?(:telegram)
  end

  def whats_app_onboarding_allowed?
    whats_app_configured? && onboarding_allowed?(:whats_app)
  end

  def telegram_bot
    Telegram.bots[id]
  end

  def twilio_instance
    Twilio::REST::Client.new(twilio_api_key_sid, twilio_api_key_secret, twilio_account_sid)
  end

  def threema_instance
    Threema.new(api_identity: threemarb_api_identity, api_secret: threemarb_api_secret, private_key: threemarb_private)
  end

  def contributors_tags_with_count
    ActsAsTaggableOn::Tag
      .for_tenant(id)
      .joins(:taggings)
      .where(taggings: { taggable_type: Contributor.name, taggable_id: Contributor.active })
      .select('tags.id, tags.name, count(taggings.id) as taggings_count')
      .group('tags.id')
      .all
      .map do |tag|
        {
          id: tag.id,
          name: tag.name,
          value: tag.name,
          count: tag.taggings_count,
          color: ApplicationController.helpers.color_from_id(tag.id)
        }
      end
  end

  private

  def set_telegram_webhook
    return unless saved_change_to_telegram_bot_username? && saved_change_to_telegram_bot_api_key?

    TelegramAdapter::SetWebhookUrlJob.perform_later(organization_id: id)
  end

  def notify_admin
    return unless business_plan_id_changed? && upgraded_business_plan_at.present?

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.send_business_plan_upgraded_message!(admin, self)
    end
  end

  def notify_admin_of_welcome_message_change
    return unless saved_change_to_onboarding_success_heading? || saved_change_to_onboarding_success_text?

    WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob.perform_later(organization_id: id)
  end
end
