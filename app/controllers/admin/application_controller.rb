# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :authorize_admin
    around_action :switch_locale

    def authorize_admin
      head :forbidden unless current_user.admin?
    end

    # The main application uses a German locale, for the
    # admin dashboard we want to use the default English
    # locale provided by administrate.
    def switch_locale(&action)
      I18n.with_locale(:en, &action)
    end
  end
end
