# frozen_string_literal: true

class ComponentAttributeBag
  include ActionView::Helpers::TagHelper

  attr_reader :attrs

  def initialize(**attrs)
    @attrs = attrs
  end

  def to_s
    # rubocop:disable Rails/OutputSafety
    tag_builder.tag_options(attrs).to_s.strip.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def merge(**additional_attrs)
    new_attrs = attrs.dup

    if attrs.key?(:class) && additional_attrs.key?(:class)
      new_attrs[:class] = "#{attrs[:class]} #{additional_attrs[:class]}"
      additional_attrs = additional_attrs.except(:class)
    end

    self.class.new(**new_attrs.deep_merge(additional_attrs))
  end

  def defaults(**default_attrs)
    self.class.new(**default_attrs).merge(attrs)
  end

  private

  def tag_builder
    @tag_builder ||= TagBuilder.new(self)
  end
end
