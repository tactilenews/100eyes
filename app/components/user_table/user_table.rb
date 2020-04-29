# frozen_string_literal: true

module UserTable
  class UserTable < ViewComponent::Base
    def initialize(*); end

    def call
      content_tag(:table, @content, class: 'UserTable')
    end
  end
end
