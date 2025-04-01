# frozen_string_literal: true

module Requests
  class GenerateCsvService < ApplicationService
    attr_reader :request, :headers, :file

    def initialize(request_id:)
      @request = Request.find(request_id)
      @headers = ['ID', 'Name', 'Text', 'Gesendet am']
      @file = Tempfile.new(request.title.parameterize.underscore.to_s)
    end

    # rubocop:disable Metrics/AbcSize
    def call
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        writer << [request.id, request.user.name, request.text, request.broadcasted_at.strftime('%Y-%m-%d um %H:%M')]
        request.messages.where(broadcasted: false).where.not(text: [nil, '']).reverse_order.each do |message|
          writer << [message.id, message.sender.name, message.text, message.created_at.strftime('%Y-%m-%d um %H:%M')]
        end
      end
      file
    end
    # rubocop:enable Metrics/AbcSize
  end
end
