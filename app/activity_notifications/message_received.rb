# frozen_string_literal: true

# To deliver this notification:
#
# MessageReceived.with(contributor: @contributor, request: @request).deliver_later(current_user)
# MessageReceived.with(contributor: @contributor, request: @request).deliver(current_user)

class MessageReceived < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor, :request

  # Define helper methods to make rendering easier.
  #
  def message
    t('.message',
      contributor_name: params[:contributor].name,
      request_title:  params[:request].title,
      count: group_by_request_id[params[:request].id].count
      )
  end

  def group_by_request_id
    ActivityNotification.where(type: 'MessageReceived').group_by { |notification| notification.params[:request].id }
  end

  # def url
  #   request_path(params[:id])
  # end
end
