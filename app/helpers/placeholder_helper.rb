# frozen_string_literal: true

module PlaceholderHelper
  def replace_placeholder(string, placeholder, replacement)
    string.gsub(/{{\s*#{placeholder}\s*}}/i, replacement)
  end
end
