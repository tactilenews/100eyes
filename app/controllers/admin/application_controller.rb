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
  end
end
