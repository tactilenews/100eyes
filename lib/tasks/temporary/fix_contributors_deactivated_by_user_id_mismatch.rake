# frozen_string_literal: true

namespace :contributors do
  desc 'Fix mismatch where a contributor can be active, but have been deactivate by a user'
  task fix_mismatch_deactivated_by_user_id: :environment do
    ActiveRecord::Base.transaction do
      Contributor.where(deactivated_at: nil).where.not(deactivated_by_user_id: nil).find_each do |contributor|
        contributor.deactivated_by_user_id = nil
        contributor.save!
        print '.'
      end
    end
  end
end
