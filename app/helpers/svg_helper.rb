# frozen_string_literal: true

module SvgHelper
  def svg(file)
    path = Rails.root.join / 'public' / "#{file}.svg"

    # rubocop:disable Rails/OutputSafety
    return File.read(path).html_safe if File.exist?(path)
    # rubocop:enable Rails/OutputSafety
  end
end
