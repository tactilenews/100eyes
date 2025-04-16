# frozen_string_literal: true

module Requests
  class GenerateCsvService < ApplicationService
    attr_reader :request, :headers, :file

    def initialize(request_id:)
      @request = Request.find(request_id)
      @headers = ['ID', 'SENDER', 'TEXT']
    end

    def call
      CSV.generate(write_headers: true, headers: headers) do |writer|
        writer << [request.id, I18n.t('service.requests.generate_csv_service.sender_info.request', sender_name: request.user.name, sent_at: request.broadcasted_at.strftime('%Y-%m-%d um %H:%M')), request.text]
        request.messages.includes(:sender).where(broadcasted: false).where.not(text: [nil, '']).reverse_order.each do |message|
          writer << [message.id, I18n.t('service.requests.generate_csv_service.sender_info.request', sender_name: message.sender.name, sent_at:  message.created_at.strftime('%Y-%m-%d um %H:%M')), message.text]
        end
      end
    end
  end
end
