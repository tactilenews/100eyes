# frozen_string_literal: true

class AddImageDataToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :image_data, :text
  end
end
