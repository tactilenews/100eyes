# frozen_string_literal: true

class AddOrganizationIdToRequests < ActiveRecord::Migration[6.1]
  def change
    add_reference :requests, :organization, foreign_key: true
  end
end
