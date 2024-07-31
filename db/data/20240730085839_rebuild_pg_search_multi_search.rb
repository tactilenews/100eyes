# frozen_string_literal: true

class RebuildPgSearchMultiSearch < ActiveRecord::Migration[6.1]
  def up
    PgSearch::Multisearch.rebuild(Contributor)
    PgSearch::Multisearch.rebuild(Message)
    PgSearch::Multisearch.rebuild(Request)
  end

  def down
    PgSearch::Multisearch.rebuild(Contributor)
    PgSearch::Multisearch.rebuild(Message)
    PgSearch::Multisearch.rebuild(Request)
  end
end
