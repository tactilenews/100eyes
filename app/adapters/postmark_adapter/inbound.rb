# frozen_string_literal: true

module PostmarkAdapter
  class Inbound
    def self.bounce!(mail)
      mailer_params = {
        text: I18n.t('mailer.contributor_not_found_email.text'),
        mail: {
          subject: I18n.t('mailer.contributor_not_found_email.subject'),
          message_stream: Setting.postmark_transactional_stream,
          to: mail.from.first
        }
      }
      Mailer.with(mailer_params).contributor_not_found_email
    end
  end
end
