# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    before { Setting.telegram_welcome_message = welcome_message }
    let(:welcome_message) do
      message = [
        'Herzlich Willkommen bei TestingProject.',
        'Danke, dass Sie an unserer Dialog-Recherche teilnehmen.',
        'In den kommenden Wochen nutzen wir Telegram für den Austausch.',
        'Ein Bot arbeitet wie ein Postbote für uns und stellt Fragen und Antworten zu.',
        'Ihre Nachrichten lesen und beantworten wir aber selbstverständlich persönlich.',
        'Wir freuen uns sehr auf den Dialog mit Ihnen!'
      ].join(' ')

      "#{message}\nKatharina Jakob, Jens Eber, Oliver Eberhardt, Isabelle Buckow, Astrid Csuraji und Jakob Vicari"
    end

    subject { -> { dispatch_command :start, { from: { username: 'Joe' } } } }
    it { should respond_with_message welcome_message }
  end

  describe '#message' do
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' } } } }
    it { should change { Contributor.count }.from(0).to(1) }
    describe 'created contributor' do
      before(:each) { subject.call }
      it { expect(Contributor.first.telegram_id).to eq(47) }
    end

    describe 'sending a message with a document' do
      before { Setting.telegram_unknown_content_message = "Cannot handle this, I'm sorry :(" }
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' }, document: 'something' } } }
      it { should respond_with_message "Cannot handle this, I'm sorry :(" }
    end
  end
end
