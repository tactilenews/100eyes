# frozen_string_literal: true

module SignalAdapter
  class Api
    class << self
      def perform_request(organization, request, contributor)
        uri = request.uri
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(request)
        end
        case response
        when Net::HTTPSuccess
          yield response if block_given?
        else
          error_message = JSON.parse(response.body)['error']
          if error_message.match?(/Unregistered user/)
            MarkInactiveContributorInactiveJob.perform_later(organization_id: organization.id,
                                                             contributor_id: contributor.id)
          end
          exception = SignalAdapter::BadRequestError.new(error_code: response.code, message: error_message)
          context = {
            code: response.code,
            message: response.message,
            headers: response.to_hash,
            body: error_message
          }
          ErrorNotifier.report(exception, context: context)
        end
      end
    end
  end
end
