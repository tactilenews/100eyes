# frozen_string_literal: true

module About
  class About < ApplicationComponent
    private

    def version
      Setting.git_commit_sha[0, 8]
    end

    def date
      date_time(Setting.git_commit_date.to_date, format: :default)
    end
  end
end
