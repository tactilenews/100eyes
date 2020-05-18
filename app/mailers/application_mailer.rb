# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.mailer[:from], reply_to: Rails.configuration.mailer[:from]
  layout 'mailer'
end
