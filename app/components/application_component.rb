# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentHelper
  include DateTimeHelper
  include SvgHelper
  include ColorHelper

  def initialize(styles: [], style: nil, data: {}, **)
    super

    @styles = styles
    @styles << style if style

    @data = data
  end

  private

  attr_reader :styles, :data

  def block_name
    self.class.name.demodulize
  end

  def class_names
    [block_name] + styles.map { |style| "#{block_name}--#{style.to_s.camelize(:lower)}" }
  end

  def class_attr
    class_names.join(' ')
  end

  def data_string
    data.map { |k, v| "data-#{k}=\"#{v}\"" }.join(' ')
  end
end
