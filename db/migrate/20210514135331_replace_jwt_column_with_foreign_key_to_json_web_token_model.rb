# frozen_string_literal: true

class ReplaceJwtColumnWithForeignKeyToJsonWebTokenModel < ActiveRecord::Migration[6.1]
  def change
    add_reference :json_web_tokens, :contributor, foreign_key: true
    JsonWebToken.find_each do |jwt|
      contributor = Contributor.find_by(jwt: jwt.invalidated_jwt)
      if contributor
        jwt.contributor = contributor
        jwt.save!
      end
    end
    remove_column :contributors, :jwt, :string
  end
end
