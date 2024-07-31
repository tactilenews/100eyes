# frozen_string_literal: true

class AddOrganizationIdToTaggings < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.transaction do
      organization = Organization.singleton
      return unless organization

      ActsAsTaggableOn::Tagging.find_each do |tag|
        tag.tenant = organization.id
        tag.save!
        Rails.logger.debug '.'
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      organization = Organization.singleton
      return unless organization

      ActsAsTaggableOn::Tagging.find_each do |tag|
        tag.tenant = nil
        tag.save!
        Rails.logger.debug '.'
      end
    end
  end
end
