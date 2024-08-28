# frozen_string_literal: true

class MigrateUsersToUsersOrganizations < ActiveRecord::Migration[6.1]
  def up
    User.admin(false).find_each do |user|
      UsersOrganization.create!(user_id: user.id, organization_id: user.organization_id)
    end
  end

  def down
    UsersOrganization.destroy_all
  end
end
