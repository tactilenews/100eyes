# frozen_string_literal: true

module SignalAdapter
  class AttachContributorsAvatarJob < ApplicationJob
    queue_as :attach_signal_avatar

    def perform(contributor)
      avatar = "/app/signal-cli-config/avatars/profile-#{contributor.signal_phone_number}"
      return unless File.file?(avatar)

      transliterated_filename = "#{ActiveSupport::Inflector.transliterate(contributor.name.strip).gsub(' ', '-')}-profile-pic"
      sanitized_filename = ActiveStorage::Filename.new(transliterated_filename).sanitized

      contributor.avatar.attach(io: File.open(avatar), filename: sanitized_filename)
    end
  end
end
