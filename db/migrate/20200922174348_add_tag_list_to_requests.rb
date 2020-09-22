# frozen_string_literal: true

class AddTagListToRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :requests, :tag_list, :string
  end
end
