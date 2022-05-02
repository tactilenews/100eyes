# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaintextMessage::PlaintextMessage, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { message: message } }
  let(:message) { 'Hello World!' }
  it { should have_css('.PlaintextMessage') }

  context 'given a message with leading/tailing whitespace' do
    let(:message) do
      <<~MESSAGE

        Hello World!

      MESSAGE
    end

    it 'strips whitespace' do
      expect(subject).to have_css('p', count: 1, exact_text: 'Hello World!')
    end
  end

  context 'given a message with consecutive line breaks' do
    let(:message) do
      <<~MESSAGE
        This message contains consecutive


        line breaks
      MESSAGE
    end

    it 'renders two p tags' do
      expect(subject).to have_css('p', count: 2)
    end
  end

  context 'given a message with HTML' do
    let(:message) { '<h1>Hello!</h1>' }

    it 'escapes HTML' do
      expect(subject).to have_text('<h1>Hello!</h1>')
    end
  end

  context 'given a nil message' do
    let(:message) { nil }

    it 'renders successfully' do
      expect(subject.child.inner_html).to be_empty
    end
  end

  context 'with highlight_placeholders: true' do
    let(:message) { 'Hi {{FIRST_NAME}}, how are you?' }
    let(:params) { { message: message, highlight_placeholders: true } }

    it 'does not insert newlines after placeholders' do
      expect(subject).to have_text('Hi {{FIRST_NAME}}, how are you?')
    end

    it { should have_css('.Placeholder', text: '{{FIRST_NAME}}') }
  end
end
