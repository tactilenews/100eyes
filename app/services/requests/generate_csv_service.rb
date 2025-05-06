# frozen_string_literal: true

module Requests
  class GenerateCsvService < ApplicationService
    attr_reader :request, :headers, :file

    def initialize(request_id:)
      @request = Request.find(request_id)
      @headers = %w[ID SENDER TEXT]
    end

    # rubocop:disable Metrics/AbcSize
    def call
      CSV.generate(write_headers: true, headers: headers) do |writer|
        writer << [request.id,
                   I18n.t('service.requests.generate_csv_service.sender_info.request',
                          sender_name: request.user.name,
                          sent_day: I18n.l(request.broadcasted_at, format: '%A'),
                          sent_date: I18n.l(request.broadcasted_at, format: '%Y.%m.%d'),
                          sent_at: I18n.l(request.broadcasted_at, format: '%H:%M')),
                   request.text]
        request.messages.includes(:sender).where(broadcasted: false).reverse_order.each do |message|
          text = if message.text.present? && message.files.any? { |file| file.attachment.attached? }
                   "#{I18n.t('service.requests.generate_csv_service.files_attached_with_caption')}\n#{message.text}"
                 elsif message.text.blank?
                   I18n.t('service.requests.generate_csv_service.files_attached')
                 else
                   message.text
                 end
          writer << [message.id,
                     I18n.t('service.requests.generate_csv_service.sender_info.reply',
                            sender_name: message.sender.name,
                            sent_day: I18n.l(message.created_at, format: '%A'),
                            sent_date: I18n.l(message.created_at, format: '%Y.%m.%d'),
                            sent_at: I18n.l(message.created_at, format: '%H:%M')),
                     text]
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
