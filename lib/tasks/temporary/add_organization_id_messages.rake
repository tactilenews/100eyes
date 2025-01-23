# frozen_string_literal: true

namespace :messages do
  desc 'Add organizations id to messages'
  task add_organization_id_to_messages: :environment do
    puts "Add photos_count to #{Message.count} messages"
    ActiveRecord::Base.transaction do
      Message.find_each do |message|
        message.organization_id = message.request.organization_id
        message.save
        print '.'
      end
    end
  end
end
