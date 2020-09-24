# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessageVoice::ChatMessageVoice, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:voice) { create(:voice) }
  let(:params) { { voice: voice } }
  it { should have_css('.ChatMessageVoice') }
end
