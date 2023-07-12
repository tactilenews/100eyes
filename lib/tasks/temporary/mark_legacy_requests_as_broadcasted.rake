# frozen_string_literal: true

namespace :requests do
  desc 'Mark legacy requests - created before schedule requests feature released - as broadcasted'
  task mark_legacy_requests_as_broadcasted: :environment do
    ActiveRecord::Base.transaction do
      puts "Mark #{Request.where('created_at <= ?', Time.zone.local(2023, 1, 7, 7, 40)).count} legacy requests as broadcasted."
      Request.where('created_at <= ?', Time.zone.local(2023, 1, 7, 7, 40)).find_each do |request|
        created_at = request.created_at
        request.broadcasted_at = created_at
        request.save!(validate: false)
        print '.'
      end
    end
  end
end
