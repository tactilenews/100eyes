# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.sendgrid[:from] || '100eyes@example.org'
  layout 'mailer'
end
