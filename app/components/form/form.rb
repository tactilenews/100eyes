# frozen_string_literal: true

module Form
  class Form < ApplicationComponent
    def initialize(auto_submit: false, **)
      super

      @auto_submit = auto_submit
    end

    private

    attr_reader :auto_submit

    def attrs
      super.merge(data: {
                    controller: 'form',
                    action: 'change->form#autoSubmit',
                    form_auto_submit_value: auto_submit
                  })
    end
  end
end
