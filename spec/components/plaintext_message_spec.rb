# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaintextMessage::PlaintextMessage, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { message: message } }
  let(:message) { 'Hello World!' }
  it { should have_css('.PlaintextMessage') }

  describe 'given a message with leading/tailing whitespace' do
    let(:message) do
      <<~MESSAGE

        Hello World!

      MESSAGE
    end

    it 'strips whitespace' do
      expect(subject.child.inner_html).to eq('Hello World!')
    end
  end

  describe 'given a nil message' do
    let(:message) { nil }

    it 'renders successfully' do
      expect(subject).to have_css('.PlaintextMessage')
      expect(subject.child.inner_html).to be_empty
    end
  end
end
