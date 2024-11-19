# frozen_string_literal: true

class Message::File < ApplicationRecord
  belongs_to :message
  counter_culture :message,
                  column_name: proc { |model| model.message.reply? && model.image_attachment? ? 'photos_count' : nil },
                  column_names: lambda {
                                  {
                                    Message::File.photos_of_replies => 'photos_count'
                                  }
                                }

  scope :photos_of_replies, lambda {
    joins(:message)
      .merge(Message.replies)
      .joins(attachment_attachment: :blob)
      .merge(ActiveStorage::Blob.where('"active_storage_blobs"."content_type" ~* ?', 'image'))
  }

  has_one_attached :attachment
  validates :attachment, presence: true

  def thumbnail
    attachment
  end

  def image_attachment?
    attachment.blob.content_type.match?(/image/)
  end

  def self.attach_files(files)
    files.map do |file|
      message_file = Message::File.new
      message_file.attachment.attach(file.blob)
      message_file
    end
  end
end
