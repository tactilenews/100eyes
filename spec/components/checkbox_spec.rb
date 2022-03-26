# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Checkbox::Checkbox, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { should have_css('input[type="checkbox"][value="1"]') }
  # "The HTML specification says unchecked check boxes are not successful, and thus web browsers do not send them. "
  # To be able to still send newly unchecked boxes a hidden auxiliary input field is introduced.
  # See: https://apidock.com/rails/ActionView/Helpers/FormHelper/check_box
  it { should have_css('input[type="hidden"][value="0"]', visible: false) }

  describe 'can be displayed checked and required' do
    let(:params) { { checked: true, required: true } }
    it { should have_css('input[type="checkbox"][value="1"][checked][required]') }
  end
end
