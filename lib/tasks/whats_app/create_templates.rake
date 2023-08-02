# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken
desc 'Create WhatsApp templates'
task create_whats_app_templates: :environment do
  template_hash = I18n.t('.')[:adapter][:whats_app][:request_template]
  template_hash.each do |key, value|
    WhatsAppAdapter::CreateTemplate.perform_later(template_name: key,
                                                  template_text: value.gsub('%{first_name}', '{{1}}').gsub(
                                                    '%{request_title}', '{{2}}'
                                                  ))
  end
end
# rubocop:enable Style/FormatStringToken
