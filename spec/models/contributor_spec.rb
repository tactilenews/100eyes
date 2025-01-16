# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributor, type: :model do
  shared_examples 'unique within an organization' do
    before { create(:contributor, organization: organization, **attrs) }

    it 'raises errors when not unique' do
      expect { create(:contributor, organization: organization, **attrs) }.to raise_error(ActiveRecord::RecordInvalid)
      expect do
        build(:contributor, organization: organization, **attrs).save!(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'accepts duplicates for other organizations' do
      expect { create(:contributor, **attrs) }.not_to raise_error
      expect { build(:contributor, **attrs).save!(validate: false) }.not_to raise_error
    end
  end

  let(:the_request) do
    create(:request, title: 'Hitchhiker’s Guide', text: 'What is the answer to life, the universe, and everything?',
                     organization: organization, user: user)
  end
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organizations: [organization]) }
  let(:contributor) { create(:contributor, email: 'contributor@example.org', organization: organization) }

  it 'is sorted in alphabetical order' do
    zora = create(:contributor, first_name: 'Zora', last_name: 'Zimmermann')
    adam_zimmermann = create(:contributor, first_name: 'Adam', last_name: 'Zimmermann')
    adam_ackermann = create(:contributor, first_name: 'Adam', last_name: 'Ackermann')

    expect(Contributor.first).to eq(adam_ackermann)
    expect(Contributor.second).to eq(adam_zimmermann)
    expect(Contributor.third).to eq(zora)
  end

  describe '.find_by_email' do
    subject { described_class.with_lowercased_email(address) }

    describe 'with lowercase address' do
      let(:contributor) { create(:contributor, email: 'UPPER@EXAMPLE.ORG') }
      let(:address) { 'upper@example.org' }

      it { should eq(contributor) }
    end

    describe 'with uppercase address' do
      let(:contributor) { create(:contributor, email: 'lower@example.org') }
      let(:address) { 'LOWER@EXAMPLE.ORG' }

      it { should eq(contributor) }
    end

    describe 'with multiple addresses' do
      let(:contributor) { create(:contributor, email: 'zora@example.org') }
      let(:address) { ['other@example.org', 'zora@example.org'] }

      it { should eq(contributor) }
    end
  end

  describe '#email' do
    it_behaves_like 'unique within an organization' do
      let(:attrs) { { email: 'contributor@example.org' } }
    end

    describe 'two contributor accounts without email' do
      before(:each) { create(:contributor, email: nil) }
      subject { build(:contributor, email: nil) }
      it { should be_valid }
    end

    describe 'no email' do
      subject { -> { build(:contributor, email: '').save! } }

      it { should_not raise_error }
      it { should change { Contributor.count }.from(0).to(1) }
      it { should change { Contributor.pluck(:email) }.from([]).to([nil]) }

      describe 'given an existing invalid contributor with empty string as email address' do
        before(:each) do
          build(:contributor, email: '').save!(validate: false)
        end

        it { should_not raise_error }
        it { should change { Contributor.count }.from(1).to(2) }
      end
    end
  end

  describe '#signal_phone_number' do
    it 'strips whitespaces' do
      contributor = create(:contributor, signal_phone_number: ' +49 123 456 789  ')
      expect(contributor.signal_phone_number).to eq '+49123456789'
    end

    it 'strips slashes, hypens and parantheses' do
      contributor = create(:contributor, signal_phone_number: '+49(0)/123-456789')
      expect(contributor.signal_phone_number).to eq '+49123456789'
    end

    it 'replaces leading zeros' do
      contributor = create(:contributor, signal_phone_number: '0049123456789')
      expect(contributor.signal_phone_number).to eq '+49123456789'
    end

    it 'assumes German country code by default' do
      contributor = create(:contributor, signal_phone_number: '015112345678')
      expect(contributor.signal_phone_number).to eq '+4915112345678'
    end

    it 'accepts Non-German country codes if given' do
      contributor = create(:contributor, signal_phone_number: '+33244445555')
      expect(contributor.signal_phone_number).to eq '+33244445555'
    end

    it 'can be nil' do
      expect(build(:contributor, signal_phone_number: nil)).to be_valid
    end

    it_behaves_like 'unique within an organization' do
      let(:attrs) { { signal_phone_number: '+491511234567' } }
    end

    it 'must be a valid phone number' do
      expect(build(:contributor, signal_phone_number: 'A+49151123456789')).not_to be_valid
    end
  end

  describe '#whats_app_phone_number' do
    it_behaves_like 'unique within an organization' do
      let(:attrs) { { whats_app_phone_number: '+491511234567' } }
    end
  end

  describe '#telegram_id' do
    it_behaves_like 'unique within an organization' do
      let(:attrs) { { telegram_id: 1 } }
    end
  end

  describe '#threema_id' do
    it 'can be nil' do
      contributor = build(:contributor, threema_id: nil)
      expect(contributor).to be_valid
    end

    it 'can be empty string' do
      contributor = build(:contributor, threema_id: '')
      expect(contributor).to be_valid
    end

    describe 'given a blank threema_id' do
      subject { -> { build(:contributor, threema_id: '').save! } }

      it { should_not raise_error }
      it { should change { Contributor.count }.from(0).to(1) }
      it { should change { Contributor.pluck(:threema_id) }.from([]).to([nil]) }

      describe 'given an existing invalid contributor with empty string as threema_id' do
        before(:each) do
          build(:contributor, threema_id: '').save!(validate: false)
        end

        it { should_not raise_error }
        it { should change { Contributor.count }.from(1).to(2) }
      end
    end

    describe 'invalid format' do
      context 'unsupported characters' do
        subject { -> { build(:contributor, threema_id: '%!$12345').save! } }

        it 'raises an error' do
          expect do
            subject.call
          end.to raise_error(ActiveRecord::RecordInvalid, /Threema ID ist ungültig, bitte überprüfen./)
        end

        it 'does not lookup Threema ID, as it is not valid' do
          subject.call
        rescue ActiveRecord::RecordInvalid
          expect(Threema::Lookup).not_to receive(:new)
        end
      end

      context 'invalid length' do
        subject { -> { build(:contributor, threema_id: 'invalidLength').save! } }

        it 'raises an error' do
          expect do
            subject.call
          end.to raise_error(ActiveRecord::RecordInvalid, /Threema ID ist ungültig, bitte überprüfen./)
        end

        it 'does not lookup Threema ID, as it is not valid' do
          subject.call
        rescue ActiveRecord::RecordInvalid
          expect(Threema::Lookup).not_to receive(:new)
        end
      end
    end

    describe 'Looking up Threema ID with Threema servers' do
      let(:threema) { instance_double(Threema) }
      let(:threema_lookup_double) { instance_double(Threema::Lookup) }

      before do
        allow(Threema).to receive(:new).and_return(threema)
        allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
      end

      context 'given an invalid Threema ID' do
        before do
          allow(threema_lookup_double).to receive(:key).and_return(nil)
        end

        it 'it raises an error' do
          expect do
            create(:contributor, threema_id: '12345678')
          end.to raise_error(ActiveRecord::RecordInvalid, /Threema ID ist ungültig, bitte überprüfen./)
        end
      end

      context 'given a valid Threema ID' do
        before do
          allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
        end

        it_behaves_like 'unique within an organization' do
          let(:attrs) { { threema_id: 'abcd1234' } }
        end

        it 'must be unique, ignoring case' do
          create(:contributor, threema_id: 'abcd1234', organization: organization)
          contributor = build(:contributor, threema_id: 'ABCD1234', organization: organization)
          expect(contributor).not_to be_valid
        end
      end
    end
  end

  describe '#replied_to_requests' do
    it 'omits duplicates' do
      create(:message, request: the_request, sender: contributor)
      create(:message, request: the_request, sender: contributor)

      expect(contributor.replied_to_requests).to contain_exactly(the_request)
    end
  end

  describe '#channels' do
    subject { contributor.channels }

    describe 'given a contributor without telegram or email' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
      it { should be_empty }
    end

    describe 'given a contributor with email' do
      let(:contributor) { create(:contributor, email: 'contributor@example.org') }
      it { should contain_exactly(:email) }
    end

    describe 'given a contributor with telegram and email' do
      let(:contributor) { create(:contributor, telegram_id: '123', email: 'contributor@example.org') }
      it { should contain_exactly(:telegram, :email) }
    end

    describe 'given a contributor with signal_phone_number' do
      let(:contributor) { create(:contributor, :signal_contributor) }
      it { should contain_exactly(:signal) }
    end

    describe 'given a contributor with signal_uuid' do
      let(:contributor) { create(:contributor, :signal_contributor_uuid) }
      it { should contain_exactly(:signal) }
    end
  end

  describe '#telegram?' do
    subject { contributor.telegram? }

    describe 'given a contributor with a telegram onboarding token' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_onboarding_token: 'ABC') }
      it { should be(true) }
    end

    describe 'given a contributor with a telegram_id and telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: '123') }
      it { should be(true) }
    end

    describe 'given a contributor without telegram_id and telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil) }
      it { should be(false) }
    end
  end

  describe '#email?' do
    subject { contributor.email? }

    describe 'given a contributor with an email address' do
      let(:contributor) { create(:contributor, email: 'contributor@example.org') }
      it { should be(true) }
    end

    describe 'given a contributor without an email address' do
      let(:contributor) { create(:contributor, email: nil) }
      it { should be(false) }
    end
  end

  describe '#avatar?' do
    subject { contributor.avatar? }

    describe 'given a contributor with an avatar' do
      let(:contributor) { create(:contributor, :with_an_avatar) }
      it { should be(true) }
    end

    describe 'given a contributor without an avatar' do
      let(:contributor) { create(:contributor) }
      it { should be(false) }
    end
  end

  describe '#tags?' do
    subject { contributor.tags? }

    describe 'given a contributor with tags' do
      let(:contributor) { create(:contributor, tag_list: 'teacher') }
      it { should be(true) }
    end

    describe 'given a contributor without tags' do
      let(:contributor) { create(:contributor) }
      it { should be(false) }
    end
  end

  describe '#conversations' do
    let(:received_message)  do
      create(:message, text: 'Message with the contributor as recipient', recipient: contributor)
    end
    let(:sent_message) do
      create(:message, sender: contributor)
    end
    it 'includes messages received by the contributor' do
      received_message
      expect(contributor.conversations).to include(received_message)
    end

    it 'includes messages sent by the contributor' do
      sent_message
      expect(contributor.conversations).to include(sent_message)
    end

    it 'sorts the messages so that the newest comes first' do
      received_message
      sent_message
      expect(contributor.conversations.last).to eql(received_message)
      expect(contributor.conversations.first).to eql(sent_message)
    end

    it 'does not include messages not being sent or received by the contributor' do
      other_contributor = create(:contributor)
      received_message = create(:message, text: 'Message with the contributor as recipient', recipient: other_contributor,
                                          request: the_request)
      sent_message = create(:message, request: the_request, sender: other_contributor)
      expect(contributor.conversations).not_to include(sent_message)
      expect(contributor.conversations).not_to include(received_message)
    end
  end

  describe '#conversation_about' do
    subject { contributor.conversation_about(the_request) }

    describe 'given some requests and messages' do
      let(:messages) do
        [
          create(:message, text: 'This is included', sender: contributor, request: the_request),
          create(:message, text: 'This is not included', sender: contributor, request: create(:request, text: 'Another request')),
          create(:message, text: 'This is included, too', sender: contributor, request: the_request),
          create(:message, text: 'This is not a message of the contributor', request: the_request),
          create(:message, text: 'Message with the contributor as recipient', recipient: contributor, request: the_request)
        ]
      end

      before(:each) do
        messages # make sure all records are written to the database
      end

      it { should include(messages[0]) }
      it { should_not include(messages[1]) }
      it 'should be orderd by `created_at`' do
        should eq([messages[0], messages[2], messages[4]])
      end
      it 'does not include messages of other contributors' do
        should_not include(messages[3])
      end
      it { should include(messages[4]) }
    end
  end

  describe '#reply' do
    subject { -> { contributor.reply(message_inbound_adapter) } }

    let!(:organization) { create(:organization, email_from_address: '100eyes@example.org', users_count: 2) }

    describe 'given a PostmarkAdapter::Inbound' do
      let(:mail) do
        mail = Mail.new do |m|
          m.from 'contributor@example.org'
          m.to '100eyes@example.org'
          m.subject 'This is a test email'
        end
        mail.text_part = 'This is a text body part'
        mail
      end
      let(:message_inbound_adapter) { PostmarkAdapter::Inbound.new(mail) }

      it { should_not raise_error }
      it { should_not(change { Message.count }) }

      describe 'given a recent request' do
        let!(:contributor) { create(:contributor, email: 'contributor@example.org', organization: organization) }

        before do
          the_request
        end

        it { should change { Message.count }.from(0).to(1) }
        it { should_not(change { Photo.count }) }

        context 'ActivityNotifications' do
          let!(:admin) { create(:user, admin: true) }

          it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
        end
      end
    end

    describe 'given a TelegramAdapter::Inbound' do
      subject do
        lambda do
          telegram_message = {
            'text' => 'The answer is 42.',
            'from' => {
              'id' => 4711,
              'is_bot' => false,
              'first_name' => 'Robert',
              'last_name' => 'Schäfer',
              'language_code' => 'en'
            },
            'chat' => { 'id' => 146_338_764 }
          }
          message_inbound_adapter = TelegramAdapter::Inbound.new(organization)
          message_inbound_adapter.consume(telegram_message) do |message|
            message.contributor.reply(message_inbound_adapter)
          end
        end
      end

      let!(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 4711, organization: organization) }

      it { expect { subject.call }.not_to raise_error }
      it { expect { subject.call }.not_to(change { Message.count }) }

      describe 'given a recent request' do
        before(:each) { the_request }

        it { expect { subject.call }.to change { Message.count }.from(0).to(1) }
        it { expect { subject.call }.not_to(change { Photo.count }) }

        context 'ActivityNotifications' do
          let!(:admin) { create(:user, admin: true) }

          it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
        end
      end
    end

    describe 'given a ThreemaAdapter::Inbound' do
      let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Hello World!') }
      let(:threema) { instance_double(Threema) }
      let(:threema_message) do
        ActionController::Parameters.new({
                                           'from' => threema_id,
                                           'to' => '*100EYES',
                                           'messageId' => 'dfbe859c44f15125',
                                           'date' => '1612808574',
                                           'nonce' => 'b1c80cf818e289e6b1966b9bcab6fb9fb5e31862b46d8f98',
                                           'box' => 'ENCRYPTED FILE',
                                           'mac' => '8c58e9d4d9ad1aa960a58a1f11bcf712e9fcd50319778762824d8259dcbdc639',
                                           'nickname' => 'matt.rider'
                                         })
      end
      subject do
        lambda do
          message_inbound_adapter = ThreemaAdapter::Inbound.new
          message_inbound_adapter.consume(threema_message) do |message|
            message.contributor.reply(message_inbound_adapter)
          end
        end
      end
      let(:threema_id) { 'V5EA564T' }
      let(:organization) { create(:organization, threemarb_api_identity: '*100EYES', users_count: 2) }
      let!(:contributor) { create(:contributor, :skip_validations, threema_id: threema_id, organization: organization) }

      before do
        allow(Threema).to receive(:new).and_return(threema)
        allow(threema).to receive(:receive).with({ payload: threema_message }).and_return(threema_mock)
        allow(threema_mock).to receive(:instance_of?) { false }
      end

      it { should_not raise_error }
      it { should_not(change { Message.count }) }

      describe 'given a recent request' do
        before do
          the_request
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true)
        end

        it { is_expected.to(change { Message.count }.from(0).to(1)) }
        it { should_not(change { Photo.count }) }

        context 'ActivityNotifications' do
          let!(:admin) { create(:user, admin: true) }

          it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
        end
      end
    end

    describe 'given a SignalAdapter::Inbound' do
      let(:signal_message) do
        {
          envelope: {
            source: '+4912345789',
            sourceNumber: '+4912345789',
            sourceDevice: 2,
            timestamp: 1_626_708_555_697,
            dataMessage: {
              timestamp: 1_626_708_555_697,
              message: 'Hello 100eyes',
              expiresInSeconds: 0,
              viewOnce: false
            }
          },
          account: '+4912345678'
        }
      end
      subject do
        lambda do
          message_inbound_adapter = SignalAdapter::Inbound.new
          message_inbound_adapter.consume(signal_message) do |message|
            message.contributor.reply(message_inbound_adapter)
          end
        end
      end

      let(:organization) { create(:organization, signal_server_phone_number: '+4912345678', users_count: 2) }
      let(:phone_number) { '+4912345789' }
      let!(:contributor) do
        create(:contributor, signal_phone_number: phone_number, organization: organization)
      end

      it { should_not raise_error }
      it { should_not(change { Message.count }) }

      describe 'given a recent request' do
        before(:each) { the_request }

        it { should change { Message.count }.from(0).to(1) }
        it { should_not(change { Photo.count }) }

        context 'ActivityNotifications' do
          let!(:admin) { create(:user, admin: true) }

          it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
        end
      end

      describe 'given a contributor with signal_uuid' do
        let!(:contributor) { create(:contributor, signal_uuid: 'valid_uuid') }

        before { signal_message[:envelope][:sourceUuid] = 'valid_uuid' }
      end
    end
  end

  describe '#active_request' do
    subject { contributor.active_request }

    describe 'given no request has gone out' do
      it 'is expected to be nil' do
        expect(subject).to be_nil
      end
    end

    describe 'given a request has gone out before the contributor onboarded' do
      let!(:previous_request) { create(:request, broadcasted_at: 1.day.ago, organization: contributor.organization) }

      it 'is expected to be the most recent request' do
        expect(subject).to eq(previous_request)
      end

      context 'the previous request is from a different organization' do
        before { previous_request.update!(organization: create(:organization)) }

        it 'is expected to be nil' do
          expect(subject).to be_nil
        end
      end
    end

    describe 'once a request was sent as a message to the contributor' do
      before(:each) { create(:message, request: the_request, recipient: contributor) }
      it { should eq(the_request) }
    end

    describe 'if a request was broadcasted' do
      before(:each) { the_request.update(broadcasted_at: 1.day.ago) }
      describe 'and afterwards a contributor joins' do
        before(:each) { contributor }
        it { should eq(the_request) }
      end
    end

    describe 'when many requests are sent to the contributor' do
      before(:each) do
        previous_request = create(:request, broadcasted_at: 1.day.ago)
        create(:message, request: the_request, recipient: contributor, created_at: the_request.broadcasted_at)
        create(:message, request: previous_request, recipient: contributor, created_at: previous_request.broadcasted_at)
      end

      it { should eq(the_request) }
    end

    describe 'when most recently a direct message is sent out belonging to a previous request' do
      let(:previous_request) { create(:request, broadcasted_at: 1.day.ago) }
      before(:each) do
        create(:message, request: the_request, recipient: contributor, created_at: the_request.broadcasted_at)
        create(:message, request: previous_request, recipient: contributor)
      end

      it { should eq(previous_request) }
    end

    describe 'when there is a planned request' do
      before(:each) do
        create(:request, broadcasted_at: nil, schedule_send_for: 1.day.from_now)
        create(:message, request: the_request, recipient: contributor)
      end

      it { should eq(the_request) }
    end
  end

  describe '#recent_replies' do
    subject { contributor.recent_replies }
    let(:old_date) { ActiveSupport::TimeZone['Berlin'].parse('2011-04-12 2pm') }
    let(:old_message) { create(:message, created_at: old_date, sender: contributor, request: the_request) }
    let(:another_request) { create(:request) }
    let(:old_request) { create(:request, created_at: (old_date - 1.day)) }

    before(:each) do
      create_list(:message, 3, sender: contributor, request: the_request)
      create(:message, sender: contributor, request: old_request)
      create(:message, sender: contributor, request: another_request)
      old_message
    end

    it { expect(subject.length).to eq(3) }

    it 'chooses one reply per request' do
      expect(subject.map(&:request)).to match_array([the_request, another_request, old_request])
    end

    it 'orders replies chronologically in descending order' do
      expect(subject).to eq(subject.sort_by(&:created_at).reverse)
    end

    describe 'number of database calls' do
      subject { -> { contributor.recent_replies.first.request } }
      it { should make_database_queries(count: 2) }
    end
  end

  describe '.with_tags' do
    let!(:contributors) { create_list(:contributor, 3).to_a }
    let!(:teachers) { create_list(:contributor, 2, tag_list: 'teacher').to_a }
    let!(:teaching_pig_farmer) { create(:contributor, tag_list: 'teacher,pig farmer') }

    context 'returns count of' do
      it 'all contributors if no tag_list present' do
        expect(Contributor.with_tags).to contain_exactly(*contributors, *teachers, teaching_pig_farmer)
      end

      it 'contributors with a specific tag' do
        expect(Contributor.with_tags(['teacher'])).to contain_exactly(*teachers, teaching_pig_farmer)
      end

      it 'aggregate contributors with a specific tag' do
        expect(Contributor.with_tags(['teacher', 'pig farmer'])).to contain_exactly(teaching_pig_farmer)
      end
    end
  end

  describe 'scope ::active' do
    subject { Contributor.active }

    context 'given some inactive and active contributors' do
      let!(:active_contributor) { create(:contributor, deactivated_at: nil) }
      let!(:unsubscribed_contributor) { create(:contributor, unsubscribed_at: 1.day.ago) }
      let!(:inactive_contributor) { create(:contributor, deactivated_at: 1.hour.ago) }

      it 'returns only active contributors' do
        should eq([active_contributor])
      end
    end
  end

  describe 'scope ::inactive' do
    subject { Contributor.inactive }

    context 'given some inactive and active contributors' do
      let!(:active_contributor) { create(:contributor, deactivated_at: nil) }
      let!(:unsubscribed_contributor) { create(:contributor, unsubscribed_at: 1.day.ago) }
      let!(:inactive_contributor) { create(:contributor, deactivated_at: 1.hour.ago) }

      it 'returns only inactive contributors' do
        should eq([inactive_contributor])
      end
    end
  end

  describe 'scope ::unsubscribed' do
    subject { Contributor.unsubscribed }

    context 'given some inactive and active contributors' do
      let!(:active_contributor) { create(:contributor, deactivated_at: nil) }
      let!(:unsubscribed_contributor) { create(:contributor, unsubscribed_at: 1.day.ago) }
      let!(:inactive_contributor) { create(:contributor, deactivated_at: 1.hour.ago) }

      it 'returns only inactive contributors' do
        should eq([unsubscribed_contributor])
      end
    end
  end

  describe '.active' do
    subject { contributor.active }
    it { should be(true) }

    describe 'given "deactivated_at" timestamp' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago) }
      it { should be(false) }
    end

    describe 'given "unsubscribed_at" timestamp' do
      let(:contributor) { create(:contributor, unsubscribed_at: 1.day.ago) }

      it 'should return false' do
        expect(subject).to be(false)
      end
    end
  end

  describe '.inactive' do
    subject { contributor.inactive }

    it { should be(false) }

    describe 'given "deactivated_at" timestamp' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago) }
      it { should be(true) }
    end
  end

  describe '.deactivate!(user_id:, admin: false)' do
    describe 'given an active contributor' do
      subject { contributor.deactivate!(user_id: user.id) }
      let(:contributor) { create(:contributor) }
      let(:user) { create(:user) }

      it 'deactivates the contributor' do
        expect { subject }.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it 'sets the deactivated_by_user_id to user_id' do
        expect { subject }.to change { contributor.reload.deactivated_by_user_id }.from(nil).to(user.id)
      end
    end
  end

  describe '.reactivate!' do
    subject { contributor.reactivate! }

    describe 'given a deactivated contributor' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago) }

      it 'reactivates the contributor' do
        expect { subject }.to change { contributor.reload.deactivated_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil)
      end
    end

    describe 'given a deactivated contributor by a user' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago, deactivated_by_user: user) }
      let(:user) { create(:user) }

      it 'reactivates the contributor, keeping attrs in sync' do
        expect { subject }.to change { contributor.reload.deactivated_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil)
                                                                          .and change {
                                                                                 contributor.reload.deactivated_by_user_id
                                                                               }.from(user.id).to(nil)
      end
    end
  end

  describe '.data_processing_consent' do
    subject { contributor.data_processing_consent }

    describe 'given a contributor who has given consent' do
      let(:contributor) { build(:contributor, data_processing_consented_at: 1.day.ago) }
      it { should be(true) }
      specify { expect(contributor).to be_valid }
    end

    describe 'given a contributor who has not given consent' do
      let(:contributor) { build(:contributor, data_processing_consented_at: nil) }
      it { should be(false) }
      specify { expect(contributor).not_to be_valid }
      context 'but the editor guarantees the consent' do
        before { contributor.editor_guarantees_data_consent = true }
        specify { expect(contributor).to be_valid }
      end
    end
  end

  describe '.data_processing_consent=' do
    describe 'given contributor who has given consent' do
      let(:contributor) { create(:contributor, data_processing_consent: 1.day.ago) }
      describe 'false' do
        it { expect { contributor.data_processing_consent = false }.to change { contributor.data_processing_consented_at }.to(nil) }
        it { expect { contributor.data_processing_consent = false }.to change { contributor.data_processing_consented_at? }.to(false) }
        it { expect { contributor.data_processing_consent = '0' }.to change { contributor.data_processing_consent? }.to(false) }
        it { expect { contributor.data_processing_consent = 'off' }.to change { contributor.data_processing_consent? }.to(false) }
      end
    end

    describe 'given contributor who has not given consent' do
      let(:contributor) { build(:contributor, data_processing_consented_at: nil) }
      describe 'true' do
        it {
          expect { contributor.data_processing_consent = true }
            .to change { contributor.data_processing_consented_at.is_a?(ActiveSupport::TimeWithZone) }.to(true)
        }
        it { expect { contributor.data_processing_consent = true }.to change { contributor.data_processing_consent? }.to(true) }
        it { expect { contributor.data_processing_consent = '1' }.to change { contributor.data_processing_consent? }.to(true) }
        it { expect { contributor.data_processing_consent = 'on' }.to change { contributor.data_processing_consent? }.to(true) }
      end
    end
  end

  describe '.additional_consent' do
    subject { contributor.additional_consent }

    describe 'given a contributor who has given additional consent' do
      let(:contributor) { build(:contributor, additional_consent_given_at: 1.day.ago) }
      it { should be(true) }
      specify { expect(contributor).to be_valid }
    end

    describe 'given a contributor who has not given additional consent' do
      let(:contributor) { build(:contributor, additional_consent_given_at: nil) }
      it { should be(false) }
      specify { expect(contributor).to be_valid }
    end
  end

  describe '.additional_consent=' do
    describe 'given contributor who has given additional consent' do
      let(:contributor) { create(:contributor, additional_consent: 1.day.ago) }
      describe 'false' do
        it { expect { contributor.additional_consent = false }.to change { contributor.additional_consent_given_at }.to(nil) }
        it { expect { contributor.additional_consent = false }.to change { contributor.additional_consent_given_at? }.to(false) }
        it { expect { contributor.additional_consent = '0' }.to change { contributor.additional_consent? }.to(false) }
        it { expect { contributor.additional_consent = 'off' }.to change { contributor.additional_consent? }.to(false) }
      end
    end

    describe 'given contributor who has not given additional consent' do
      let(:contributor) { build(:contributor, additional_consent_given_at: nil) }
      describe 'true' do
        it {
          expect { contributor.additional_consent = true }
            .to change { contributor.additional_consent_given_at.is_a?(ActiveSupport::TimeWithZone) }.to(true)
        }
        it { expect { contributor.additional_consent = true }.to change { contributor.additional_consent? }.to(true) }
        it { expect { contributor.additional_consent = '1' }.to change { contributor.additional_consent? }.to(true) }
        it { expect { contributor.additional_consent = 'on' }.to change { contributor.additional_consent? }.to(true) }
      end
    end
  end

  describe '.avatar_url=', vcr: { cassette_name: :download_roberts_telegram_profile_picture } do
    let(:url) { 'https://t.me/i/userpic/320/2CixclGZED6EeKGQHKm9wk2v7xKy3LWCJGHJPkgcih0.jpg' }
    subject { -> { contributor.avatar_url = url } }
    it { is_expected.to(change { contributor.avatar.attached? }.from(false).to(true)) }

    context 'given a bogus url' do
      let(:url) { 'not a url' }
      it { is_expected.not_to(change { contributor.avatar.attached? }.from(false)) }
    end

    context 'with existing avatar' do
      let(:contributor) { create(:contributor, :with_an_avatar) }
      it {
        is_expected.to(
          change { contributor.avatar.blob.filename.to_param }
            .from('example-image.png')
            .to('2CixclGZED6EeKGQHKm9wk2v7xKy3LWCJGHJPkgcih0.jpg')
        )
      }
    end
  end

  describe '.send_welcome_message!', telegram_bot: :rails do
    subject { -> { contributor.send_welcome_message!(organization) } }

    let!(:organization) do
      create(:organization, onboarding_success_heading: 'Welcome new contributor!', onboarding_success_text: 'You onboarded successfully.')
    end
    let(:contributor) do
      create(:contributor, telegram_id: nil, email: nil, threema_id: nil, signal_phone_number: nil, whats_app_phone_number: nil,
                           organization: organization)
    end

    it { should_not have_enqueued_job }

    context 'signed up via telegram' do
      let(:expected_job_args) do
        { organization_id: organization.id, contributor_id: contributor.id,
          text: "<b>Welcome new contributor!</b>\nYou onboarded successfully." }
      end
      let(:contributor) do
        create(:contributor, telegram_id: nil, telegram_onboarding_token: 'ABCDEF', email: nil, organization: organization)
      end
      it { should_not have_enqueued_job }

      context 'and connected' do
        let(:contributor) { create(:contributor, :telegram_contributor, organization: organization) }
        it { should enqueue_job(TelegramAdapter::Outbound::Text).with(expected_job_args) }
      end
    end

    context 'signed up via threema' do
      let(:expected_job_args) do
        { organization_id: organization.id, contributor_id: contributor.id,
          text: "*Welcome new contributor!*\nYou onboarded successfully." }
      end
      let(:contributor) { create(:contributor, :skip_validations, :threema_contributor, organization: organization) }
      it { should enqueue_job(ThreemaAdapter::Outbound::Text).with(expected_job_args) }
    end

    context 'signed up via email' do
      let(:contributor) { create(:contributor, email: 'text@example.org') }
      it {
        should enqueue_job.with(
          'PostmarkAdapter::Outbound',
          'welcome_email',
          'deliver_now',
          {
            params: { organization: organization, contributor: contributor },
            args: []
          }
        )
      }
    end
  end

  describe '#after_create_commit' do
    subject { create(:contributor, organization: organization) }

    before { create(:user, admin: true) }

    it_behaves_like 'an ActivityNotification', 'OnboardingCompleted', 2
  end
end
