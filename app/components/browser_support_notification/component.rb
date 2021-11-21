# frozen_string_literal: true

require 'browser'

module BrowserSupportNotification
  class Component < ApplicationComponent
    private

    def browser_supported?
      browser = Browser.new(request.user_agent)
      browser.firefox? || browser.chrome? || browser.edge?
    end
  end
end
