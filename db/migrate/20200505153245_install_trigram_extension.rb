# frozen_string_literal: true

class InstallTrigramExtension < ActiveRecord::Migration[6.0]
  def up
    execute 'CREATE EXTENSION pg_trgm;'
  end

  def down
    execute 'DROP EXTENSION pg_trgm;'
  end
end
