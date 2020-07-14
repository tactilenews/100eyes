# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentHelper
  include DateTimeHelper

  def initialize(styles: [], **)
    @styles = styles
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
