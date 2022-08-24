# frozen_string_literal: true

# To deliver this notification:
#
# ChatMessageSent.with(contributor: @contributor, request: @request, user: @user, message: @message).deliver_later(current_user)
# ChatMessageSent.with(contributor: @contributor, request: @request, user: @user, message: @message).deliver(current_user)

class ChatMessageSent < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor, :request, :user, :message

  # Define helper methods to make rendering easier.
  #
  # rubocop:disable Rails/OutputSafety
  def text
    t('.text_html',
      contributor_name: record.name,
      request_title: request.title,
      user_name: user.name,
      count: count).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(request, anchor: "message-#{message.id}")
  end

  def link_text
    t('.link_text')
  end

  def record
    params[:contributor]
  end

  def request
    params[:request]
  end

  def user
    params[:user]
  end

  def message
    params[:message]
  end

  def count
    query = base_query
    requests_responded_to_by_user = query.where('params @> ?', Noticed::Coder.dump(request: request).to_json)
                                         .where('params @> ?', Noticed::Coder.dump(user: user).to_json)
    with_contributor = requests_responded_to_by_user.where('params @> ?', Noticed::Coder.dump(contributor: record).to_json)
    without_contributor = requests_responded_to_by_user - with_contributor
    without_contributor.pluck(:params).pluck(:contributor).pluck(:id).uniq.count
  end

  def base_query
    Current.user
           .notifications
           .chat_message_sent
  end
end
