# frozen_string_literal: true

module TelegramAdapter
  class FileTooLargeError < StandardError
    def initialize(contributor_name:)
      super("#{contributor_name} send a file that is too large to be downloaded via Telegram API")
    end
  end
end
