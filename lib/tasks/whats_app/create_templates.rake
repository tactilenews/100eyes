# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken
desc 'Create WhatsApp templates'
task create_whats_app_templates: :environment do
  default_welcome_message = ["*#{File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))}*",
                             File.read(File.join('config', 'locales', 'onboarding',
                                                 'success_text.txt'))].join("\n\n").gsub('100eyes', '{{1}}')
  default_welcome_message_hash = { default_welcome_message: default_welcome_message }
  requests_hash = I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
    value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
  end
  template_hash = default_welcome_message_hash.merge(requests_hash)
  template_hash.each do |key, value|
    WhatsAppAdapter::CreateTemplate.perform_later(template_name: key, template_text: value)
  end
end
# rubocop:enable Style/FormatStringToken
