# frozen_string_literal: true

class WhatsApp::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token

  def message
    response = Twilio::TwiML::MessagingResponse.new
    response.message do |message|
      message.body('Hello World!')
    end
  end
end
