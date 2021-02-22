# frozen_string_literal: true

module CopyButton
  class CopyButton < ApplicationComponent
    def initialize(copy: nil, label: nil, success: nil, **)
      super

      @copy = copy
      @label = label
      @success = success || I18n.t('components.copy_button.success')
    end

    private

    attr_reader :copy, :label, :success

    def attrs
      super.defaults(
        data: {
          controller: 'copy-button',
          action: 'click->copy-button#copy',
          copy_button_copy_value: copy,
          copy_button_success_class: 'CopyButton--success'
        }
      )
    end
  end
end
