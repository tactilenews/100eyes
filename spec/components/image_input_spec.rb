# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageInput::ImageInput, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { { id: :logo } }

  it { should have_css('.ImageInput') }
  it { should have_css('input[type="file"][id="logo"][name="logo"][hidden]', visible: :all) }

  context 'without existing upload' do
    it { should have_text('Noch kein Bild hochgeladen') }
    it { should have_css('svg.Icon') }
    it { should have_button('Bild hochladen') }
    it { should_not have_css('.ImageInput-selectedImage') }
  end

  context 'with existing upload' do
    let(:file) { fixture_file_upload('example-image.png') }
    let(:blob) { ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename) }

    let(:params) { { id: :logo, value: blob } }

    it { should have_text('example-image.png') }
    it { should have_css('img[src$="/example-image.png"]') }
    it { should have_button('Bild ersetzen') }
    it { should_not have_css('.ImageInput-emptyState') }
  end
end
