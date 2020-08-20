# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentHelper
  include DateTimeHelper
  include SvgHelper

  def initialize(styles: [], style: nil, **)
    @styles = styles
    @styles << style if style
  end

  private

  attr_reader :styles

  def block_name
    self.class.name.demodulize
  end

  def modifiers
    styles.map { |style| "Input--#{style}" }
  end

  def class_names
    [block_name] + styles.map { |style| "#{block_name}--#{style}" }
  end

  def class_attr
    class_names.join(' ')
  end
end
