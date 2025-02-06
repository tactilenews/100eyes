# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class Contributor < ApplicationRecord
  include PgSearch::Model
  include ActiveModel::Validations

  attr_accessor :editor_guarantees_data_consent

  after_create_commit :notify_recipient

  multisearchable against: %i[first_name last_name username note],
                  additional_attributes: ->(contributor) { { organization_id: contributor.organization_id } }

  has_many :replies, class_name: 'Message', as: :sender, dependent: :destroy
  has_many :received_messages, class_name: 'Message', inverse_of: :recipient, foreign_key: 'recipient_id', dependent: :destroy
  has_many :whats_app_template_messages, lambda { |contributor|
                                           contributor.received_messages
                                         }, source: :whats_app_template, through: :received_messages
  has_many :replied_to_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :replies
  has_many :received_requests, -> { broadcasted.reorder(broadcasted_at: :desc).distinct }, source: :request, through: :received_messages
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  belongs_to :organization, optional: true
  belongs_to :deactivated_by_user, class_name: 'User', optional: true

  has_one_attached :avatar
  has_one :json_web_token, dependent: :destroy
  accepts_nested_attributes_for :json_web_token

  acts_as_taggable_on :tags
  acts_as_taggable_tenant :organization_id

  default_scope { order(:first_name, :last_name) }
  scope :active, -> { where(deactivated_at: nil, unsubscribed_at: nil) }
  scope :inactive, -> { where.not(deactivated_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

  phony_normalize :signal_phone_number, default_country_code: 'DE'
  phony_normalize :whats_app_phone_number, default_country_code: 'DE'

  validates :signal_phone_number, phony_plausible: true
  validates :whats_app_phone_number, phony_plausible: true
  validates :data_processing_consent, acceptance: true, unless: proc { |c| c.editor_guarantees_data_consent }

  validates :email, uniqueness: { case_sensitive: false, scope: :organization }, allow_nil: true, 'valid_email_2/email': true
  validates :threema_id, uniqueness: { case_sensitive: false, scope: :organization }, allow_blank: true
  validates :telegram_id, uniqueness: { scope: :organization }, allow_nil: true
  validates :signal_phone_number, uniqueness: { scope: :organization }, allow_nil: true
  validates :whats_app_phone_number, uniqueness: { scope: :organization }, allow_nil: true

  validates :avatar, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 0..(5.megabytes) }

  validates_with ThreemaValidator, if: -> { threema_id.present? }

  scope :with_tags, lambda { |tag_list = []|
    tag_list.blank? ? all : tagged_with(tag_list)
  }

  scope :with_email, -> { where.not(email: nil) }
  scope :with_threema, -> { where.not(threema_id: nil) }
  scope :with_telegram, -> { where.not(telegram_id: nil) }
  scope :with_signal, -> { where.not(signal_phone_number: nil, signal_uuid: nil) }
  scope :with_whats_app, -> { where.not(whats_app_phone_number: nil) }

  before_validation do
    self.email = nil if email.blank?
    self.threema_id = nil if threema_id.blank?
  end

  def self.with_lowercased_email(email)
    find_by('lower(email) in (?)', Array.wrap(email).map(&:downcase))
  end

  def reply(message_decorator)
    ActiveRecord::Base.transaction do
      message = message_decorator.message
      message.request = received_messages.first&.request
      message.save!
    end
  end

  def send_welcome_message!(organization)
    [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound,
     WhatsAppAdapter::Delegator.new(organization)].each do |adapter|
      adapter.send_welcome_message!(self, organization)
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def conversations
    Message
      .where(recipient: self)
      .or(Message.where(sender: self))
  end

  def conversation_about(request)
    Message
      .where(request: request, sender: self)
      .or(Message.where(request: request, recipient: self))
      .reorder(created_at: :asc)
  end

  def channels
    { email: email?, signal: signal?, telegram: telegram?, threema: threema?, whats_app: whats_app? }.select { |_k, v| v }.keys
  end

  def telegram?
    telegram_id.present? || telegram_onboarding_token.present?
  end

  def email?
    email.present?
  end

  def threema?
    threema_id.present?
  end

  def signal?
    signal_phone_number.present? || signal_uuid.present? || signal_onboarding_token.present?
  end

  def whats_app?
    whats_app_phone_number.present?
  end

  def signal_attr
    signal_phone_number || signal_uuid
  end

  def avatar?
    avatar.attached?
  end

  def tags?
    tags.any?
  end

  def most_recent_replies_to_some_request
    result = replies.with_request_attached.includes(:recipient, :request).reorder(created_at: :desc)
    result = result.group_by(&:request).values # array or groups
    result = result.map(&:first) # choose most recent message per group
    result.sort_by(&:created_at).reverse # ensure descending order
  end

  def active?
    deactivated_at.nil? && unsubscribed_at.nil?
  end

  alias active active?

  def inactive?
    !active?
  end

  alias inactive inactive?

  def avatar_url=(url)
    return unless url

    begin
      remote_file_location = URI(url)
    rescue URI::InvalidURIError
      return
    end
    avatar.attach(io: remote_file_location.open, filename: File.basename(remote_file_location.path))
  end

  def deactivate!(user_id: nil, admin: false)
    self.deactivated_by_admin = admin
    update!(deactivated_at: Time.current, deactivated_by_user_id: user_id)
  end

  def reactivate!
    return if active?

    update!(
      deactivated_at: nil,
      deactivated_by_user_id: nil,
      deactivated_by_admin: false
    )
  end

  def data_processing_consent=(value)
    self.data_processing_consented_at = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
  end

  def data_processing_consent?
    data_processing_consented_at.present?
  end

  alias data_processing_consent data_processing_consent?

  def additional_consent=(value)
    self.additional_consent_given_at = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
  end

  def additional_consent?
    additional_consent_given_at.present?
  end

  alias additional_consent additional_consent?

  def stats
    {
      counts: {
        received_requests: received_requests.select(:request_id).distinct.count,
        replied_to_requests: replied_to_requests.select(:request_id).distinct.count,
        replies: replies.count
      }
    }
  end

  private

  def notify_recipient
    OnboardingCompleted.with(contributor_id: id, organization_id: organization.id).deliver_later(organization.users + User.admin.all)
  end
end
# rubocop:enable Metrics/ClassLength
