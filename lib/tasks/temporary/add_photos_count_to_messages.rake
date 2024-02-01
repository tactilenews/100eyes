# frozen_string_literal: true

namespace :messages do
  desc 'Add photos count to messages to remove nil default'
  task add_photos_count_to_requests: :environment do
    puts "Add photos_count to #{Message.count} messages"
    ActiveRecord::Base.transaction do
      Message.find_each do |message|
        message.photos_count = message.photos.count
        message.save
        print '.'
      end
    end
  end
end
