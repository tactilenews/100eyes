# frozen_string_literal: true

module About
  class About < OrganizationComponent
    private

    def version
      ENV.fetch('GIT_COMMIT_SHA', nil)[0, 8]
    end

    def date
      date_time(ENV.fetch('GIT_COMMIT_DATE', nil).to_date, format: :default)
    end
  end
end
