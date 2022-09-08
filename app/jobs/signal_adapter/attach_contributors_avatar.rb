module SignalAdapter
  class AttachContributorsAvatar < ApplicationJob
    queue_as :attach_signal_avatar

    def perform(contributor)
      avatar = "/app/signal-cli-config/avatars/profile-#{contributor.signal_phone_number}"
      if File.file?(avatar)
        contributor.avatar.attach(io: File.open(avatar), filename: "#{contributor.name.delete(' ').underscore}_profile_pic")
      end
    end
  end
end
