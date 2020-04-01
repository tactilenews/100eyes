module FormInput
  class FormInput < ViewComponent::Base
    def initialize(label:)
      @label = label
    end

    def id
      @label.parameterize
    end
  end
end
