# frozen_string_literal: true

class AttributeBag
  include ActionView::Helpers::TagHelper

  def initialize(attrs = {})
    @attrs = attrs
  end

  def ==(other)
    to_hash == other.to_hash
  end

  def to_s
    # rubocop:disable Rails/OutputSafety
    tag_builder.tag_options(attrs).to_s.strip.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def to_hash
    attrs
  end

  def merge(additional_attrs = {})
    new_attrs = attrs.dup

    if attrs.key?(:class) && additional_attrs.key?(:class)
      new_attrs[:class] = "#{attrs[:class]} #{additional_attrs[:class]}"
      additional_attrs = additional_attrs.except(:class)
    end

    self.class.new(**new_attrs.deep_merge(additional_attrs))
  end

  def defaults(default_attrs = {})
    self.class.new(**default_attrs).merge(**attrs)
  end

  def slice(*slice_attrs)
    self.class.new(**attrs.slice(*slice_attrs))
  end

  def except(*except_attrs)
    self.class.new(**attrs.except(*except_attrs))
  end

  private

  attr_reader :attrs

  def tag_builder
    @tag_builder ||= TagBuilder.new(self)
  end
end
