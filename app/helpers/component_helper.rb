module ComponentHelper
  def component(name, props = {}, &block)
    path = "#{name}/#{name}"
    class_name = path.camelize

    unless class_name.safe_constantize
      raise ArgumentError.new("View component #{class_name} is not defined.")
    end

    render(class_name.constantize.new(**props), &block)
  end

  alias c component
end
