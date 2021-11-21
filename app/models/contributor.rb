# frozen_string_literal: true

class Contributor < ApplicationRecord
  include PgSearch::Model

  attr_accessor :editor_guarantees_data_consent

  multisearchable against: %i[first_name last_name username note]

  has_many :replies, class_name: 'Message', inverse_of: :sender, foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', inverse_of: :recipient, foreign_key: 'recipient_id', dependent: :destroy
  has_many :replied_to_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :replies
  has_many :received_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :received_messages

  has_one_attached :avatar
  has_one :json_web_token, dependent: :destroy
  has_one :most_recent_reply, lambda {
    select('DISTINCT ON (sender_id) *')
      .reorder(:sender_id, created_at: :desc)
  }, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy, inverse_of: false
  accepts_nested_attributes_for :json_web_token

  acts_as_taggable_on :tags

  default_scope { order(:first_name, :last_name) }
  scope :active, -> { where(deactivated_at: nil) }
  scope :inactive, -> { where.not(deactivated_at: nil) }

  phony_normalize :signal_phone_number, default_country_code: 'DE'

  validates :signal_phone_number, phony_plausible: true
  validates :data_processing_consent, acceptance: true, unless: proc { |c| c.editor_guarantees_data_consent }

  validates :email, uniqueness: { case_sensitive: false }, allow_nil: true, 'valid_email_2/email': true
  validates :threema_id, uniqueness: { case_sensitive: false }, allow_blank: true, format: { with: /\A[A-Za-z0-9]+\z/ }, length: { is: 8 }
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :signal_phone_number, uniqueness: true, allow_nil: true

  validates :avatar, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 0..(5.megabytes) }

  scope :with_tags, lambda { |tag_list = []|
    tag_list.blank? ? all : tagged_with(tag_list)
  }

  before_validation do
    self.email = nil if email.blank?
    self.threema_id = nil if threema_id.blank?
  end

  def self.with_lowercased_email(email)
    find_by('lower(email) in (?)', Array.wrap(email).map(&:downcase))
  end

  def self.all_tags_with_count
    ActsAsTaggableOn::Tag
      .joins(:taggings)
      .select('tags.id, tags.name, count(taggings.id) as taggings_count')
      .group('tags.id')
      .where(taggings: { taggable_type: name })
      .all
      .map do |tag|
        {
          id: tag.id,
          name: tag.name,
          value: tag.name,
          count: tag.taggings_count,
          color: Contributor.tag_color_from_id(tag.id)
        }
      end
  end

  def self.tag_color_from_id(tag_id)
    ApplicationController.helpers.color_from_id(tag_id)
  end

  def reply(message_decorator)
    request = active_request or return nil
    ActiveRecord::Base.transaction do
      message = message_decorator.message
      message.request = request
      message.save!
    end
  end

  def send_welcome_message!
    [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound].each do |adapter|
      adapter.send_welcome_message!(self)
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def conversation_about(request)
    Message
      .where(request: request, sender: self)
      .or(Message.where(request: request, recipient: self))
      .reorder(created_at: :asc)
  end

  def channels
    { email: email?, signal: signal?, telegram: telegram?, threema: threema? }.select { |_k, v| v }.keys
  end

  def active_request
    received_requests.reorder(created_at: :desc).first || Request.reorder(created_at: :desc).first
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
    signal_phone_number.present?
  end

  def avatar?
    avatar.attached?
  end

  def tags?
    tags.any?
  end

  def recent_replies
    result = replies.includes(:request, :sender).reorder(created_at: :desc)
    result = result.group_by(&:request).values # array or groups
    result = result.map(&:first) # choose most recent message per group
    result.sort_by(&:created_at).reverse # ensure descending order
  end

  def active?
    deactivated_at.nil?
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

  def active=(value)
    self.deactivated_at = ActiveModel::Type::Boolean.new.cast(value) ? nil : Time.current
  end

  def data_processing_consent=(value)
    self.data_processing_consented_at = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
  end

  def data_processing_consent?
    data_processing_consented_at.present?
  end
  alias data_processing_consent data_processing_consent?
end
