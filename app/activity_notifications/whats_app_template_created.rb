# frozen_string_literal: true

class WhatsAppTemplateCreated < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :organization_id

  def to_database
    {
      type: self.class.name,
      organization_id: params[:organization_id]
    }
  end

  def group_key
    { "#{self.class.to_s.underscore}_organization_id".to_sym => record.id }
  end

  def record_for_avatar
    record.organization.users.sample
  end

  def group_message(*)
    t('.text_html')
  end

  def url
    organization_settings_path(record.organization, anchor: 'onboarding-success-section')
  end

  def link_text
    t('.link_text')
  end
end
