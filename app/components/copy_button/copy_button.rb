# frozen_string_literal: true

module CopyButton
  class CopyButton < ApplicationComponent
    def initialize(copy: nil, url: nil, key: nil, label: nil, loading: nil, success: nil, **)
      super

      @copy = copy
      @url = url
      @key = key
      @label = label
      @loading = loading || I18n.t('components.copy_button.loading')
      @success = success || I18n.t('components.copy_button.success')
    end

    private

    attr_reader :copy, :url, :key, :label, :loading, :success

    def attrs
      super.defaults(
        data: {
          controller: 'copy-button',
          action: 'click->copy-button#copy',
          copy_button_copy_value: copy,
          copy_button_url_value: url,
          copy_button_key_value: key
        }
      )
    end
  end
end
