# frozen_string_literal: true

namespace :requests do
  desc 'Add replies count to requests to remove nil default'
  task add_replies_count_to_requests: :environment do
    puts "Add replies_count to #{Request.count} requests"
    ActiveRecord::Base.transaction do
      Request.find_each do |request|
        request.replies_count = request.replies.count
        request.save
        print '.'
      end
    end
  end
end
