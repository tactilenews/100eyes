# frozen_string_literal: true

module SignalAdapter
  class Api
    class << self
      def perform_request(request, contributor)
        uri = request.uri
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(request)
        end
        case response
        when Net::HTTPSuccess
          yield response if block_given?
        else
          error_message = JSON.parse(response.body)['error']
          mark_contributor_as_inactive(contributor) if error_message.match?(/User is not registered/)
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

      private

      def mark_contributor_as_inactive(contributor)
        contributor.update(deactivated_at: Time.current)
        ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        User.admin.find_each do |admin|
          PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
        end
      end
    end
  end
end
