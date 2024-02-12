# frozen_string_literal: true

namespace :messages do
  desc 'Add photos count to messages to remove nil default'
  task add_photos_count_to_messages: :environment do
    puts "Add photos_count to #{Message.count} messages"
    ActiveRecord::Base.transaction do
      Message.replies.find_each do |message|
        message.photos_count = message.photos.count
        message.photos_count += message.files.joins(:attachment_blob).where(active_storage_blobs: {
                                                                              content_type: %w[image/jpg image/jpeg
                                                                                               image/png image/gif]
                                                                            }).size
        message.save
        print '.'
      end
    end
  end
end
