# frozen_string_literal: true

require 'browser'

module Textarea
  class Textarea < ApplicationComponent
    def initialize(id: nil, value: nil, show_emoji_picker_hint: false, highlight_placeholders: false, **)
      super

      @id = id
      @value = value
      @show_emoji_picker_hint = show_emoji_picker_hint
      @highlight_placeholders = highlight_placeholders
    end

    private

    attr_reader :id, :value, :show_emoji_picker_hint, :highlight_placeholders
    alias show_emoji_picker_hint? show_emoji_picker_hint
    alias highlight_placeholders? highlight_placeholders

    def styles
      return super unless highlight_placeholders

      super << :highlighted
    end

    def attrs
      super.defaults(id: id, name: id)
    end

    def emoji_picker_supported?
      windows_emoji_picker_supported? || macos_emoji_picker_supported?
    end

    def windows_emoji_picker_supported?
      # The native emoji picker was introduced in Windows 10
      # https://support.microsoft.com/en-us/windows/windows-10-keyboard-tips-and-tricks-588e0b72-0fff-6d3f-aeee-6e5116097942
      browser.platform.windows?('>=10')
    end

    def macos_emoji_picker_supported?
      # The native emoji picker was introduced in macOS 10.13
      # https://support.apple.com/guide/mac-help/use-emoji-and-symbols-mchlp1560/10.13/mac/10.13
      browser.platform.mac?('>=10.13')
    end

    def browser
      Browser.new(request.user_agent)
    end
  end
end
