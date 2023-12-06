# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageInput::ImageInput, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: :logo } }

  it { is_expected.to have_css('.ImageInput') }
  it { is_expected.to have_css('input[type="file"][id="logo"][name="logo"][hidden]', visible: :all) }

  context 'without existing upload' do
    it { is_expected.to have_text('Kein Bild ausgewählt') }
    it { is_expected.to have_css('svg.Icon') }
    it { is_expected.to have_button('Bild auswählen') }
    it { is_expected.not_to have_css('.ImageInput-selectedImage') }
  end

  context 'with existing upload' do
    let(:file) { fixture_file_upload('example-image.png') }
    let(:blob) { ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename) }

    let(:params) { { id: :logo, value: blob } }

    it { is_expected.to have_text('example-image.png') }
    it { is_expected.to have_css('img[src$="/example-image.png"]') }
    it { is_expected.to have_button('Bild ersetzen') }
    it { is_expected.not_to have_css('.ImageInput-emptyState') }
  end
end
