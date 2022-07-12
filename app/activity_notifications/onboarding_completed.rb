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
  def message
    t('.message',
      contributor_name: params[:contributor].name,
      contributor_channel: params[:contributor].channels.first.to_s.capitalize)
  end

  # def url
  #   contributor_path(params[:id])
  # end
end
