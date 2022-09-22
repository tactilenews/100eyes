# frozen_string_literal: true

module PlaintextMessage
  class PlaintextMessage < ApplicationComponent
    include PlaceholderHelper

    def initialize(message: nil, highlight_placeholders: false, **)
      super

      @message = message
      @highlight_placeholders = highlight_placeholders
    end

    private

    attr_reader :message, :highlight_placeholders
    alias highlight_placeholders? highlight_placeholders

    def empty?
      message_content.empty?
    end

    def rendered
      rendered = html_escape(message_content)
      rendered = simple_format(rendered)

      if highlight_placeholders?
        replace_placeholder(rendered, t('request.personalization.first_name'), component('placeholder') { "{{#{t('request.personalization.first_name')}}}" }.strip)
      else
        rendered
      end
    end

    def message_content
      (message || content || '').strip
    end
  end
end
