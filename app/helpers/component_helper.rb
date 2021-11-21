# frozen_string_literal: true

module ComponentHelper
  def component(name, props = {}, &block)
    component_class = class_from_identifier(name)
    render(component_class.new(**props), &block)
  end

  def component_inline(name, props = {}, &block)
    component_class = class_from_identifier(name)
    render_inline(component_class.new(**props), &block)
  end

  alias c component

  private

  def class_from_identifier(name)
    path = "#{name}/component"
    class_name = path.camelize

    unless class_name.safe_constantize
      raise ArgumentError, "View component #{class_name} is not defined."
    end

    class_name.constantize
  end
end
