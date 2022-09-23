# frozen_string_literal: true

namespace :messages do
  desc 'Add sender_type to messages for exisiting records after changing to polymorphic association'
  task add_sender_type_to_messages: :environment do
    puts "Add sender_type to #{Message.where.not(sender_id: nil).count} messages"
    ActiveRecord::Base.transaction do
      Message.where.not(sender_id: nil).find_each do |message|
        message.update(sender_type: 'Contributor')
        print '.'
      end
    end
  end
end
