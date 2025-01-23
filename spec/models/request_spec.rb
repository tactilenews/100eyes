# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:user) { create(:user, organizations: [organization]) }

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
          create(:message, sender: recipient, request: request) do |message|
            create(:photo, message: message)
          end
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

  describe '#trigger_broadcast' do
    context 'with a request not scheduled for' do
      let!(:request) { create(:request, schedule_send_for: nil) }

      it 'schedules a job to broadcast the request and returns nil' do
        expect(request.trigger_broadcast).to have_been_enqueued.with(request.id)
      end
    end

    context 'with a request scheduled to be sent out immediately' do
      let!(:request) { create(:request, schedule_send_for: Time.current) }

      it 'schedules a job to broadcast the request and returns nil' do
        expect(request.trigger_broadcast).to have_been_enqueued.with(request.id)
      end
    end

    context 'with a scheduled for request' do
      let!(:request) { create(:request, schedule_send_for: 1.day.from_now) }

      it 'delays the job for the future and returns the run time' do
        expect { request.trigger_broadcast }.to change(DelayedJob, :count).from(0).to(1)
        expect(Delayed::Job.last.run_at).to be_within(1.second).of(request.schedule_send_for)
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
    end

    describe 'given a planned request' do
      before { request.schedule_send_for = 1.hour.from_now }

      let!(:admin) { create_list(:user, 2, admin: true) }
      let!(:other_organization) { create(:organization, users_count: 2) }

      it_behaves_like 'an ActivityNotification', 'RequestScheduled', 3
    end
  end
end
