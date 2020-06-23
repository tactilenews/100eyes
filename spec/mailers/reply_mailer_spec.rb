# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReplyMailer, type: :mailer do
  describe 'new_question_email' do
    let(:mail) { described_class.with(email: 'user@example.org').user_not_found_email }

    describe '#subject' do
      subject { mail.subject }
      it { should eq('Wir können deine E-Mail Adresse nicht zuordnen') }
    end

    describe '#body' do
      subject { mail.body }
      it { should eq('Wir können deine E-Mail Adresse user@example.org leider keinem unserer Benutzerprofile zuordnen.') }
    end
  end
end
