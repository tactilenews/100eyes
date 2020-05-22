# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :reply
  has_many_attached :images

  def telegram_message=(message)
    return unless message['photo']

    message['photo'].each do |telegram_file|
      file_id = telegram_file['file_id']
      bot_token = "bot#{Rails.application.credentials.dig(:telegram, :bots, Rails.configuration.bot_id)}"
      uri = URI("https://api.telegram.org/#{bot_token}/getFile")
      uri.query = URI.encode_www_form({ file_id: file_id })
      response = JSON.parse(URI.open(uri).read)
      file_path = response.dig('result', 'file_path')
      remote_file_location = URI("https://api.telegram.org/file/#{bot_token}/#{file_path}")
      images.attach(io: URI.open(remote_file_location), filename: File.basename(remote_file_location.path))
    end
  end
end
