# frozen_string_literal: true

require 'net/http'

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

      case response.code
      when 200
        mark_contributor_as_inactive(response, contributor)
      when 400..499
        report_error(response)
      end
    end
  end

  def self.mark_contributor_as_inactive(response, contributor)
    return if JSON.parse(response.body).first['registered']

    contributor.update(deactivated_at: Time.current)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
  end

  def self.report_error(response)
    ErrorNotifier.report(Net::HTTPServerException, context: {
                           code: response.code,
                           message: response.message,
                           headers: response.to_hash,
                           body: response.body
                         })
  end
end
