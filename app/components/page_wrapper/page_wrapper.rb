# frozen_string_literal: true

module PageWrapper
  class PageWrapper < ApplicationComponent
    def initialize(*); end

    def call
      content_tag(:div, @content, class: 'c-page-wrapper')
    end
  end
end
