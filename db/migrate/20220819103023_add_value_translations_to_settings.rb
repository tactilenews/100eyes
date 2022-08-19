# frozen_string_literal: true

class AddValueTranslationsToSettings < ActiveRecord::Migration[6.1]
  def change
    I18n.available_locales.each do |locale|
      add_column :settings, "value_#{locale}".to_sym, :text
    end
  end
end
