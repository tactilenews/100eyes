# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.mailer[:from], reply_to: Rails.configuration.mailer[:reply_to]
  layout 'mailer'
end
