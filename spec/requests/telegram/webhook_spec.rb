# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    let(:welcome_message) do
      ['Hallo, schön, dass du an #100-test-eyes teilnimmst. Ich bin der Bot der',
       'Dialogsoftware #100eyes. Ich freue mich auf den Dialog mit dir. Bitte',
       'antworte kurz mit "Hallo" auf diese Nachricht, damit ich weiß, dass',
       'ich dir auf diesem Weg Nachrichten schicken darf.'].join(' ')
    end
    subject { -> { dispatch_command :start, { from: { username: 'Joe' } } } }
    it { should respond_with_message welcome_message }
  end

  describe '#message' do
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' } } } }
    it { should change { User.count }.from(0).to(1) }
    describe 'created user' do
      before(:each) { subject.call }
      it { expect(User.first.telegram_id).to eq(47) }
    end
  end
end
