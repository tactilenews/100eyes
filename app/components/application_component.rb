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
    @attrs = attrs.except(*params)
  end

  private

  attr_reader :styles, :data

  def t(key, options = {})
    scope = self.class.name.demodulize.underscore
    scoped_key = "components.#{scope}.#{key}"

    return I18n.t(scoped_key, options) if I18n.exists?(scoped_key)

    I18n.t(key, options)
  end

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
end
