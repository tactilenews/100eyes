# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramMessage do
  let(:telegram_message) { TelegramMessage.new message }
  describe '#text' do
    subject { telegram_message.text }

    describe 'given a message with a `text` attribute' do
      let(:message) { { text: 'Ich bin eine normale Nachricht' } }
      it { should eq('Ich bin eine normale Nachricht') }
    end

    describe 'given a photo with a `caption`' do
      let(:message) do
        {  photo: [
          { file_id: 'AAA', file_size: 6293, width: 320, height: 120 },
          { file_id: 'AAB', file_size: 23_388, width: 800, height: 299 },
          { file_id: 'AAC', file_size: 41_585, width: 1280, height: 478 }
        ], caption: 'Das hier ist die Überschrift eine Fotos' }
      end
      it { should eq('Das hier ist die Überschrift eine Fotos') }
    end
  end
end
