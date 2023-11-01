# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken
desc 'Create WhatsApp templates'
task create_whats_app_templates: :environment do
  welcome_message_hash = { welcome_message: I18n.t('.')[:adapter][:whats_app][:welcome_message].gsub('%{project_name}', '{{1}}') }
  requests_hash = I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
    value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
  end
  template_hash = welcome_message_hash.merge(requests_hash)
  template_hash.each do |key, value|
    WhatsAppAdapter::CreateTemplate.perform_later(template_name: key, template_text: value)
  end
end
# rubocop:enable Style/FormatStringToken
