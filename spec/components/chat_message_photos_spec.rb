# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessagePhotos::ChatMessagePhotos, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { photos: [] } }
  it { should have_css('.ChatMessagePhotos') }
end
