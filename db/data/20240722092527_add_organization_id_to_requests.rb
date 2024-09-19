# frozen_string_literal: true

class AddOrganizationIdToRequests < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.transaction do
      organization = Organization.first
      return unless organization

      Request.find_each do |request|
        request.organization_id = organization.id
        request.save!(validate: false)
        Rails.logger.debug '.'
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      organization = Organization.first
      return unless organization

      Request.find_each do |request|
        request.organization_id = nil
        request.save!(validate: false)
        Rails.logger.debug '.'
      end
    end
  end
end
