# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentHelper
  include DateTimeHelper
  include SvgHelper
  include ColorHelper

  def initialize(styles: [], style: nil, **attrs)
    super

    @styles = styles
    @styles << style if style

    params = self.class.instance_method(:initialize).parameters.map(&:last)
    @attrs = attrs.except(*params, :style, :styles)
  end

  private

  attr_reader :styles

  def attrs
    AttributeBag.new(class: class_attr).merge(@attrs)
  end

  def block_name
    self.class.name.demodulize
  end

  def class_names
    [block_name] + styles.map { |style| "#{block_name}--#{style.to_s.camelize(:lower)}" }
  end

  def class_attr
    class_names.join(' ')
  end

  def virtual_path
    "components.#{self.class.name.demodulize.underscore}"
  end
end
