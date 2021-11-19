# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :have_current_user do |user|
  match do |response|
    current_user(response).present? && current_user(response) == user
  end

  description do
    "have current user #{user&.id}"
  end

  failure_message_for_should do |_response|
    "have current user #{user&.id}, but got #{user&.id}"
  end

  def current_user(response)
    response.request.env[:clearance].current_user
  end
end
