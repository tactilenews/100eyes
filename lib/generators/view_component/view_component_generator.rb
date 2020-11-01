# frozen_string_literal: true

class ViewComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :css, type: :boolean, default: true
  class_option :js, type: :boolean, default: true
  class_option :template, type: :boolean, default: true
  class_option :spec, type: :boolean, default: true

  BASE_PATH = 'app/components/'
  SPEC_PATH = 'spec/components/'

  def initialize(args, *options)
    super

    # Every component should be inside its own model,
    # e.g. my_button will create MyButton::MyButton
    @class_path.unshift(file_name)
  end

  def create_class_file
    template 'component.rb', component_file_path
  end

  def create_template_file
    return unless options[:template]

    template 'component.html.erb', component_file_path('html.erb')
  end

  def create_css_file
    return unless options[:css]

    template 'component.css', component_file_path('css')
  end

  def create_js_file
    return unless options[:js]

    template 'component.js', component_file_path('js')
  end

  def create_spec_file
    return unless options[:spec]

    template 'component_spec.rb', "#{SPEC_PATH}#{file_name}_spec.rb"
  end

  private

  def component_file_path(extension = 'rb')
    BASE_PATH + file_path + ".#{extension}"
  end
end
