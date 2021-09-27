# frozen_string_literal: true

module Form
  class Form < ApplicationComponent
    private

    def attrs
      super.merge(data: {
                    controller: 'form',
                    action: 'submit->form#disableSubmit',
                    form_loading_label_value: I18n.t('components.form.loading')
                  })
    end
  end
end
