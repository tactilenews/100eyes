# frozen_string_literal: true

module Requests
  class GenerateCsvService < ApplicationService
    attr_reader :request, :headers, :file

    def initialize(request_id:)
      @request = Request.find(request_id)
      @headers = ['ID', 'Name', 'Text', 'Gesendet am']
    end

    def call
      CSV.generate(write_headers: true, headers: headers) do |writer|
        writer << [request.id, request.user.name, request.text, request.broadcasted_at.strftime('%Y-%m-%d um %H:%M')]
        request.messages.includes(:sender).where(broadcasted: false).where.not(text: [nil, '']).reverse_order.each do |message|
          writer << [message.id, message.sender.name, message.text, message.created_at.strftime('%Y-%m-%d um %H:%M')]
        end
      end

      # binding.pry
    end
  end
end
