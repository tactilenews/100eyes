# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadButton::UploadButton, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: 'avatar', input_label: 'Avatar', button_label: 'Upload new avatar' } }

  it { is_expected.to have_css('.UploadButton') }
  it { is_expected.to have_css('button', text: 'Upload new avatar') }
  it { is_expected.to have_css('label', text: 'Avatar') }
  it { is_expected.to have_css('input[type="file"]') }
end
