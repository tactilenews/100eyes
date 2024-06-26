# frozen_string_literal: true

module SignalAdapter
  class AttachContributorsAvatarJob < ApplicationJob
    queue_as :attach_signal_avatar

    def perform(contributor_id:)
      contributor = Contributor.find_by(id: contributor_id)
      return unless contributor

      avatar = "/app/signal-cli-config/avatars/profile-#{contributor.signal_uuid}"
      return unless File.file?(avatar)

      contributor.avatar.attach(io: File.open(avatar), filename: contributor.id)
    end
  end
end
