# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:user) { create(:user) }

  let(:request) do
    Request.new(
      title: 'Hitchhiker’s Guide',
      text: 'What is the answer to life, the universe, and everything?',
      user: user,
      schedule_send_for: Time.current,
      organization: organization
    )
  end

  subject { request }

  describe 'validations' do
    it { is_expected.to be_valid }

    context 'no title' do
      before { request.title = '' }

      it { is_expected.not_to be_valid }
    end

    context 'no text' do
      before { request.text = '' }

      it { is_expected.not_to be_valid }

      describe 'with file attached' do
        before do
          request.files.attach(
            io: Rails.root.join('example-image.png').open,
            filename: 'example-image.png'
          )
        end

        it { is_expected.to be_valid }
      end
    end

    context 'no organization' do
      before { request.organization = nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'text shorter than or equal to 1500 chars' do
      before { request.text = Faker::Lorem.characters(number: 1_500) }

      it { is_expected.to be_valid }
    end

    context 'text longer than 1500 chars' do
      before { request.text = Faker::Lorem.characters(number: 1_501) }

      it { is_expected.not_to be_valid }
    end

    context 'jpg' do
      before { request.files = [fixture_file_upload('profile_picture.jpg')] }

      it { is_expected.to be_valid }
    end

    context 'jpeg' do
      before { request.files = [fixture_file_upload('matt.jpeg')] }

      it { is_expected.to be_valid }
    end

    context 'gif' do
      before { request.files = [fixture_file_upload('thinking-cat.gif')] }

      it { is_expected.to be_valid }
    end

    context 'svg' do
      before { request.files = [fixture_file_upload('channel_mail.svg')] }

      it { is_expected.not_to be_valid }
    end
  end

  it 'has title, text, and user_id' do
    expect(subject.attributes.keys).to include('title', 'text', 'user_id')
  end

  context 'files' do
    before do
      request.files.attach(
        io: Rails.root.join('example-image.png').open,
        filename: 'example-image.png'
      )
    end

    it 'attached' do
      expect(subject.files).to be_attached
    end
  end

  it 'is by default sorted in reverse chronological order' do
    oldest_request = create(:request, created_at: 2.hours.ago)
    newest_request = create(:request, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_request)
    expect(described_class.last).to eq(oldest_request)
  end

  describe 'request tag_list persists' do
    let!(:contributor) { create(:contributor, tag_list: ['programmer']) }
    let!(:request) { create(:request, tag_list: ['programmer']) }

    before(:each) do
      contributor.tag_list = ''
      contributor.save
      contributor.reload
    end

    it 'even with no contributors with tag' do
      expect(contributor.tag_list).to eq([])
      expect(Contributor.all_tags.map(&:name)).to eq([])
      request.reload
      expect(request.tag_list).to eq(['programmer'])
      expect(Request.all_tags.map(&:name)).to eq(['programmer'])
    end
  end

  describe '#personalized_text' do
    let(:contributor) { build(:contributor, first_name: 'Zora', last_name: 'Zimmermanne') }
    let(:request) { build(:request, text: text) }

    subject { request.personalized_text(contributor) }

    context 'with uppercase placeholder' do
      let(:text) { 'Hi {{VORNAME}}, how are you?' }
      it { should eq('Hi Zora, how are you?') }
    end

    context 'with lowercase placeholder' do
      let(:text) { 'Hi {{vorname}}, how are you?' }
      it { should eq('Hi Zora, how are you?') }
    end

    context 'with mixed-cased placeholder' do
      let(:text) { 'Hi {{Vorname}}, how are you?' }
      it { should eq('Hi Zora, how are you?') }
    end

    context 'with optional whitespace in placeholder' do
      let(:text) { 'Hi {{ VORNAME }}, how are you?' }
      it { should eq('Hi Zora, how are you?') }
    end

    context 'with multiple placeholders' do
      let(:text) { '{{VORNAME}}! {{VORNAME}}! {{VORNAME}}!' }
      it { should eq('Zora! Zora! Zora!') }
    end

    context 'with unsupported placeholder' do
      let(:text) { 'This is {{NOT_SUPPORTED}}' }
      it { should eq('This is {{NOT_SUPPORTED}}') }
    end

    context 'if name contains leading/trailing whitespace' do
      let(:text) { 'Hi {{VORNAME}}, how are you?' }
      let(:contributor) { build(:contributor, first_name: ' Zora ') }
      it { should eq('Hi Zora, how are you?') }
    end
  end

  describe '#messages_by_contributor' do
    subject { request.messages_by_contributor }
    let(:request) { create(:request) }

    describe 'with messages by multiple contributors' do
      let(:request) { create(:request, :with_interlapping_messages_from_two_contributors) }

      it 'groups by contributor' do
        expect(subject.keys).to all(be_a Contributor)
        expect(subject.length).to eq(2)
      end

      it 'sorts by most recent message' do
        expect(subject.keys.first.name).to eq('Adam Ackermann')
        expect(subject.keys.second.name).to eq('Zora Zimmermann')
      end
    end

    it 'ignores broadcasted messages' do
      create(:message, request: request, broadcasted: true)
      expect(subject).to be_empty
    end
  end

  describe '#stats' do
    let(:request) { create(:request) }
    let(:user) { create(:user) }
    let(:stats) { request.stats }

    describe 'given a number of requests, replies and photos' do
      before(:each) do
        create_list(:message, 2)
        delivered_messages = create_list(:message, 7, :outbound, request: request, broadcasted: true)
        create(:message, :with_file, :outbound, request: request, broadcasted: false, attachment: fixture_file_upload('example-image.png'))
        # _ is some unresponsive recipient
        responsive_recipient, _, *other_recipients = delivered_messages.map(&:recipient)
        create_list(:message, 3, request: request, sender: responsive_recipient)
        other_recipients.each do |recipient|
          create(:message, :with_a_photo, sender: recipient, request: request)
          create(:message, :with_file, sender: recipient, request: request, attachment: fixture_file_upload('example-image.png'))
          create(:message, :with_file, sender: recipient, request: request, attachment: fixture_file_upload('invalid_profile_picture.pdf'))
        end
        request.reload
      end

      describe '[:counts][:replies]' do
        subject { stats[:counts][:replies] }
        it { should eq(18) }

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: user, broadcasted: true)
          end

          it 'are excluded' do
            should eq(18)
          end
        end
      end

      describe '[:counts][:contributors]' do
        subject { stats[:counts][:contributors] }
        it { should eq(6) } # unique contributors

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: user, broadcasted: true)
          end

          it 'are excluded' do
            should eq(6)
          end
        end
      end

      describe '[:counts][:recipients]' do
        subject { stats[:counts][:recipients] }
        it { should eq(8) }

        describe 'messages to us' do
          before do
            create(:message, request: request, sender: create(:contributor), broadcasted: true, recipient: nil)
          end

          it 'are excluded' do
            should eq(8)
          end
        end
      end

      describe '[:counts][:photos]' do
        subject { stats[:counts][:photos] }
        it { should eq(10) } # unique photos
      end
    end
  end

  describe '::after_create' do
    subject { -> { request.save! } }

    before do
      request.files.attach(
        io: Rails.root.join('example-image.png').open,
        filename: 'example-image.png'
      )
      allow(Request).to receive(:broadcast!).and_call_original # is stubbed for every other test
    end

    describe 'given some existing contributors in the moment of creation' do
      before(:each) do
        create(:contributor, id: 1, email: 'somebody@example.org')
        create(:contributor, id: 2, email: nil, telegram_id: 22)
      end

      it { should change { Message.count }.from(0).to(2) }
      it { should change { Message.pluck(:recipient_id).sort }.from([]).to([1, 2]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([request.user.id, request.user.id]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true, true]) }
      it { should change { Message::File.count }.from(0).to(2) }
    end

    describe 'creates message only for contributors tagged with tag_list' do
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          tag_list: 'programmer',
          user: user,
          organization: organization
        )
      end
      before(:each) do
        create(:contributor, id: 1, email: 'somebody@example.org', tag_list: ['programmer'], organization: organization)
        create(:contributor, id: 2, email: nil, telegram_id: 22, organization: organization)
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([1]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([request.user.id]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true]) }
    end

    describe 'given contributors who are deactivated' do
      before(:each) do
        create(:contributor, :inactive, id: 3, email: 'deactivated@example.org')
        create(:contributor, id: 4, email: 'activated@example.org')
        create(:contributor, :inactive, id: 5, telegram_id: 24)
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([4]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([request.user.id]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true]) }
    end
  end

  describe '::after_update_commit' do
    before do
      allow(Request).to receive(:broadcast!).and_call_original
      create(:contributor)
    end
    subject { request.update!(params) }

    describe '#broadcast_updated_request' do
      context 'not planned request' do
        before { request.save! }

        let(:params) { { text: 'I have new text' } }

        it 'does not broadcast request' do
          expect(Request).not_to receive(:broadcast!)

          subject
        end

        it 'does not create a notification' do
          expect { subject }.not_to(change { ActivityNotification.where(type: RequestScheduled.name).count })
        end
      end

      context 'planned request' do
        let(:params) { { schedule_send_for: 1.day.from_now } }

        it 'calls broadcast! to schedule request' do
          expect(Request).to receive(:broadcast!).with(request)

          subject
        end

        it 'creates a notification' do
          expect { subject }.to(change { ActivityNotification.where(type: RequestScheduled.name).count }.from(0).to(1))
        end

        context 'no change to scheduled time' do
          before { request.save! }
          let(:params) { { text: 'Fixed typo' } }

          it 'does not broadcast request' do
            expect(Request).not_to receive(:broadcast!)

            subject
          end
        end

        context 'schedule_send_for set to nil' do
          before { request.update(schedule_send_for: 1.day.from_now) }
          let(:params) { { schedule_send_for: nil } }

          it 'does not create a notification' do
            expect { subject }.not_to(change { ActivityNotification.where(type: RequestScheduled.name).count })
          end

          it 'broadcasts the messages' do
            expect { subject }.to(change(Message, :count).from(0).to(1))
          end
        end

        context 'schedule_send_for set to time in past' do
          before { request.update(schedule_send_for: 1.day.from_now) }
          let(:params) { { schedule_send_for: 1.day.ago } }

          it 'does not create a notification' do
            expect { subject }.not_to(change { ActivityNotification.where(type: RequestScheduled.name).count })
          end

          it 'broadcasts the messages' do
            expect { subject }.to(change(Message, :count).from(0).to(1))
          end
        end
      end
    end
  end
end
