# frozen_string_literal: true

require 'net/http'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
module SignalAdapter
  class VerifyNumberRegisteredJob < ApplicationJob
    def perform(contributor)
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/search?numbers=#{contributor.signal_phone_number}")
      request = Net::HTTP::Get.new(url.to_s, {
                                     Accept: 'application/json',
                                     'Content-Type': 'application/json'
                                   })
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.request(request)
      end
      case response.code.to_i
      when 200
        return if JSON.parse(response.body).first['registered']

        contributor.update(deactivated_at: Time.current)
        ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        User.admin.find_each do |admin|
          PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin,
                                                                    contributor,
                                                                    I18n.t(
                                                                      'jobs.signal_adapter.verify_number_registered_job.unregistered',
                                                                      phone_number: contributor.signal_phone_number
                                                                    ))
        end
      when 400..499
        ErrorNotifier.report(Net::HTTPServerException, context: {
                               code: response.code,
                               message: response.message,
                               headers: response.to_hash,
                               body: response.body
                             })
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
