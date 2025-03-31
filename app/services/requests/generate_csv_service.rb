# frozen_string_literal: true

module Requests
  class GenerateCsvService < ApplicationService
    attr_reader :request, :headers, :file

    def initialize(request_id:)
      @request = Request.find(request_id)
      @headers = ['ID', 'Frage ID', 'Absendername', 'Title', 'Text', 'Replied at']
      @file = Tempfile.new(request.title.parameterize.underscore.to_s)
    end

    # rubocop:disable Metrics/AbcSize
    def call
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        writer << [request.id, nil, request.user.name, request.title, request.text]
        request.messages.where(broadcasted: false).where.not(text: [nil, '']).reverse_order.each do |message|
          writer << [nil, message.request.id, message.sender.name, nil, message.text, message.reply? ? message.created_at : '']
        end
      end
      file
    end
    # rubocop:enable Metrics/AbcSize
  end
end
