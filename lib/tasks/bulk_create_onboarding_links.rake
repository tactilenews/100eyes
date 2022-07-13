# frozen_string_literal: true

require 'csv'

desc 'Bulk create onboarding links, export to csv'
task :bulk_create_onboarding_links, [:count] => :environment do |_t, args|
  include Rails.application.routes.url_helpers

  file = Rails.root.join('public/onboariding_links.csv')
  headers = ['Onboarding-Links']
  CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
    args[:count].to_i.times do
      payload = { invite_code: SecureRandom.base64(16), action: 'onboarding' }
      jwt = JsonWebToken.encode(payload)
      writer << [onboarding_url(jwt: jwt)]
    end
  end
end
