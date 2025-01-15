# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class Text < ApplicationJob
      queue_as :default

      retry_on Net::HTTPServerError, wait: ->(executions) { executions * 3 } do |job, exception|
        if job.executions == 5
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: exception.code, message: exception.message)
          context = { message_id: job.arguments.first[:message_id], recipient: job.payload[:to] }
          ErrorNotifier.report(exception, context: context)
        end
      end

      def perform(contributor_id:, type:, text: nil, message_id: nil)
        @contributor = Contributor.find(contributor_id)
        @type = type

        @text = text
        @message = Message.find(message_id) if message_id

        url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
        headers = { 'D360-API-KEY' => contributor.organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url, headers)

        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      attr_reader :contributor, :type, :text, :message

      private

      def payload
        case type
        when :text
          text_payload
        when :welcome_message_template
          welcome_message_payload
        when :request_template
          request_payload
        end
      end

      def text_payload
        base_payload.merge({
                             type: 'text',
                             text: {
                               body: text || message.text
                             }
                           })
      end

      def welcome_message_payload
        template_name = "welcome_message_#{contributor.organization.project_name.parameterize.underscore}"
        template_payload(template_name)
      end

      def time_of_day
        current_time = Time.current
        morning = current_time.change(hour: 6)
        day = current_time.change(hour: 11)
        evening = current_time.change(hour: 17)
        night = current_time.change(hour: 23)

        case current_time
        when morning..day
          'morning'
        when day..evening
          'day'
        when evening..night
          'evening'
        else
          'night'
        end
      end

      def request_payload
        template_name = "new_request_#{time_of_day}_#{rand(1..3)}"
        template_payload(template_name).deep_merge(template_components)
      end

      def template_payload(name)
        base_payload.merge(
          type: 'template',
          template: {
            language: {
              policy: 'deterministic',
              code: 'de'
            },
            name: name
          }
        )
      end

      def base_payload
        {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: contributor.whats_app_phone_number.split('+').last
        }
      end

      def template_components
        {
          template: {
            components: [
              {
                type: 'body',
                parameters: [
                  {
                    type: 'text',
                    text: contributor.first_name
                  },
                  {
                    type: 'text',
                    text: message.request.title
                  }
                ]
              }
            ]
          }
        }
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          external_id = JSON.parse(response.body)['messages'].first['id']
          if type.eql?(:request_template)
            Message::WhatsAppTemplate.create!(message_id: message.id, external_id: external_id)
          else
            message&.update!(external_id: external_id)
          end
        when Net::HTTPClientError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          context = { message_id: message&.id, recipient: payload[:to] }
          ErrorNotifier.report(exception, context: context)
        end
      end
    end
  end
end
