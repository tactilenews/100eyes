module ComponentHelper
  def component(name, props = {}, &block)
    component_class = class_from_identifier(name)
    render(component_class.new(**props), &block)
  end

  def component_inline(name, props = {}, &block)
    component_class = class_from_identifier(name)
    render_inline(component_class.new(**props), &block)
  end

  private

  def class_from_identifier(name)
    path = "#{name}/#{name}"
    class_name = path.camelize

    unless class_name.safe_constantize
      raise ArgumentError.new("View component #{class_name} is not defined.")
    end

    class_name.constantize
  end

  alias c component
end
