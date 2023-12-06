# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Textarea::Textarea, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { is_expected.to have_css('textarea.Textarea-input') }

  context 'given an id' do
    let(:params) { { id: 'message' } }

    it { is_expected.to have_css('textarea[id="message"]') }
  end

  context 'given a value' do
    let(:params) { { value: 'Lorem Ipsum dolor sit amet.' } }

    it { is_expected.to have_text('Lorem Ipsum dolor sit amet.') }
  end

  context 'when required' do
    let(:params) { { required: true } }

    it { is_expected.to have_css('textarea[required]') }
  end

  context 'given a placeholder' do
    let(:params) { { placeholder: 'Enter your message here!' } }

    it { is_expected.to have_css('textarea[placeholder="Enter your message here!"]') }
  end

  describe 'emoji picker hint' do
    before { allow(request).to receive(:user_agent).and_return(user_agent) }

    let(:user_agent) { nil }

    it { is_expected.not_to have_css('.Textarea-emojiPickerHint') }

    context 'with show_emoji_picker_hint: true' do
      let(:params) { { show_emoji_picker_hint: true } }

      context 'on unsupported platform' do
        let(:user_agent) { 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36' }

        it { is_expected.not_to have_css('.Textarea-emojiPickerHint') }
      end

      context 'on Windows' do
        let(:user_agent) do
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
        end

        it { is_expected.to have_css('kbd', text: 'Windows-Taste') }
        it { is_expected.to have_css('kbd', text: 'Punkt') }
      end

      context 'on macOS' do
        let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko)' }

        it { is_expected.to have_css('kbd', text: 'Command') }
        it { is_expected.to have_css('kbd', text: 'Control') }
        it { is_expected.to have_css('kbd', text: 'Leertaste') }
      end
    end
  end

  describe 'placeholder highlights' do
    it { is_expected.not_to have_css('.Textarea-highlights') }

    context 'with highlight_placeholder: true' do
      let(:params) { { highlight_placeholders: true } }

      it { is_expected.to have_css('.Textarea-highlights') }
    end
  end
end
