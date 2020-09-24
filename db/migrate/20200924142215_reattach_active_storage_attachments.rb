# frozen_string_literal: true

class ReattachActiveStorageAttachments < ActiveRecord::Migration[6.0]
  def change
    ActiveStorage::Attachment.where(name: 'image').each do |att|
      photo = Photo.find(att.record_id)
      photo.attachment.attach(att.blob)
      att.purge
    end
  end
end
