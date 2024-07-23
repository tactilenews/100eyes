# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageInput::ImageInput, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:params) { { id: :logo } }

  it { should have_css('.ImageInput') }
  it { should have_css('input[type="file"][id="logo"][name="logo"][hidden]', visible: :all) }

  context 'without existing upload' do
    it { should have_text('Kein Bild ausgewählt') }
    it { should have_css('svg.Icon') }
    it { should have_button('Bild auswählen') }
    it { should_not have_css('.ImageInput-selectedImage') }
  end

  context 'with existing upload' do
    before do
      organization.onboarding_logo.attach(io: file, filename: file.original_filename)
    end
    let(:file) { fixture_file_upload('example-image.png') }
    let(:value) { organization.onboarding_logo }

    let(:params) { { id: :logo, value: value } }

    it { should have_text('example-image.png') }
    it { should have_css('img[src$="/example-image.png"]') }
    it { should have_button('Bild ersetzen') }
    it { should_not have_css('.ImageInput-emptyState') }
  end
end
