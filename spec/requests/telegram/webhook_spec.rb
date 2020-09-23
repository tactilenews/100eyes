# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    let(:welcome_message) do
      message = [
        'Herzlich Willkommen bei #50survivors.',
        'Danke, dass Du an unserer Dialogrecherche teilnimmst.',
        'In den kommenden Wochen nutzen wir Telegram für den Austausch.',
        'Ein Bot arbeitet wie ein Postbote für uns und stellt Fragen und Antworten zu.',
        'Deine Nachrichten lesen und beantworten wir aber selbstverständlich persönlich.',
        'Wir freuen uns sehr auf den Dialog mit Dir!'
      ].join(' ')

      message + "\nIsabelle Buckow, Astrid Csuraji, Jakob Vicari und Bertram Weiß"
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

    describe 'sending an voice message' do
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' }, voice: 'something' } } }
      it { should respond_with_message I18n.t('telegram.unknown_content_message') }
    end
  end
end
