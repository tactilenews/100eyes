# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordInput::PasswordInput, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: 'password', minlength: 33 } }

  it { should have_css('.PasswordInput') }
  it { should have_css('button', text: 'Passwort einblenden') }

  it { should have_css('input[type="password"][required][minlength="33"]') }

  it { should_not have_css('ul#password-validations') }
  it { should_not have_css('input[aria-describedby="password-validations"]') }

  context 'show_validations=true' do
    let(:params) { { id: 'password', minlength: 33, show_validations: true } }

    it { should have_css('ul#password-validations') }
    it { should have_css('input[aria-describedby="password-validations"]') }

    it { should have_text('min. 33 Zeichen') }
    it { should have_text('enthält Buchstaben') }
    it { should have_text('enthält Zahlen') }
    it { should have_text('enthält Sonderzeichen') }
  end
end
