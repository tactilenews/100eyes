# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatMessageAudio::ChatMessageAudio, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:audios) { [create(:file)] }
  let(:params) { { audios: audios } }
  it { should have_css('.ChatMessageAudio') }
end
