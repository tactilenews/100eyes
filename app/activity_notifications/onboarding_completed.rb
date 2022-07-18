# frozen_string_literal: true

# To deliver this notification:
#
# OnboardingCompleted.with(contributor: @contributor).deliver_later(current_user)
# OnboardingCompleted.with(contributor: @contributor).deliver(current_user)

class OnboardingCompleted < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor

  # Define helper methods to make rendering easier.
  #
  # rubocop:disable Rails/OutputSafety
  def message
    t('.message_html',
      contributor_name: contributor.name,
      contributor_channel: contributor.channels.first.to_s.capitalize).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    contributor_path(contributor.id)
  end

  def link_text
    t('.link_text')
  end

  def contributor
    params[:contributor]
  end
end
