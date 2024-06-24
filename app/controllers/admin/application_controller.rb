# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    around_action :switch_locale

    # The main application uses a German locale, for the
    # admin dashboard we want to use the default English
    # locale provided by administrate.
    def switch_locale(&action)
      I18n.with_locale(:en, &action)
    end

    def requested_resource
      @requested_resource ||= find_resource(params[:id]).tap do |resource|
        authorize_resource(resource)
      end
    end

    def find_resource(param)
      if resource_name.eql?(:organization)
        scoped_resource.friendly.find(param)
      else
        scoped_resource.find(param)
      end
    end
  end
end
