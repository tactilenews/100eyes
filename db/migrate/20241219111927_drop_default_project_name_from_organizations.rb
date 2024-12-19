class DropDefaultProjectNameFromOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_column_default :organizations, :project_name, from: '100eyes', to: nil
  end
end
