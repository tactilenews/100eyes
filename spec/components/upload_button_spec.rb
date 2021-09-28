# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadButton::UploadButton, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { id: 'avatar', label: 'Upload new avatar' } }

  it { should have_css('.UploadButton') }
  it { should have_css('button', text: 'Upload new avatar') }
  it { should have_css('input[type="file"]') }
end
