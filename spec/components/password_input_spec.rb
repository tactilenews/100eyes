# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordInput::PasswordInput, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: 'password', minlength: 33 } }

  it { should have_css('.PasswordInput') }
  it { should have_css('button', text: 'Passwort einblenden') }

  it { should have_css('input[type="password"][required][minlength="33"]') }
end
