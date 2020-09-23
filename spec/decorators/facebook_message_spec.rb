# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FacebookMessage do
  let(:facebook_message) { FacebookMessage.new message }
  let(:message) do
    Facebook::Messenger::Incoming::Message.new(hash)
  end
  let(:hash) { { 'sender' => { 'id' => id }, 'message' => { 'text' => text, 'attachments' => attachments } } }
  let(:text) { nil }
  let(:attachments) { nil }
  let(:id) { 1 }

  describe '#text' do
    subject { facebook_message.text }
    describe 'given a message with a `text` attribute' do
      let(:text) { 'It is a truth universally acknowledged.' }
      it { should eq('It is a truth universally acknowledged.') }
    end
  end

  describe '#message' do
    let(:request) { create(:request) }
    subject { facebook_message.message }

    describe 'assigning a request and calling #save! on the message' do
      it do
        expect do
          subject.request = request
          subject.save!
        end.to(change { Message.count }.from(0).to(1))
      end
    end
  end

  describe '#sender' do
    subject { facebook_message.sender }
    let(:sender) { { 'id': 'catattack123' } }

    describe 'calling #save! on the sender' do
      it { expect { subject.save! }.to(change { User.count }.from(0).to(1)) }
    end
  end

  describe '.unknown_content' do
    subject { facebook_message.unknown_content }
    it { should be(false) }

    describe 'all attachment are photos', vcr: { cassette_name: :facebook_message_with_photo } do
      let(:attachments) do
        [
          { 'payload' => {
            'url' => 'https://scontent.xx.fbcdn.net/v/t1.15752-9/120092317_785085292275977_6878743094167703174_n.jpg?_nc_cat=110&_nc_sid=b96e70&_nc_ohc=jf8nc88iZIUAX8wk_tY&_nc_ad=z-m&_nc_cid=0&_nc_ht=scontent.xx&oh=cf1fb7d14ffc4b188d3cf02672262246&oe=5F8F0CE1'
          } }
        ]
      end
      it { should be(false) }
    end

    describe 'some file attachment', vcr: { cassette_name: :facebook_message_with_file } do
      let(:attachments) do
        [
          { 'payload' => {
            'url' => 'https://cdn.fbsbx.com/v/t59.2708-21/11392517_10205418820163799_1440647182_n.txt/test.txt?_nc_cat=104&_nc_sid=0cab14&_nc_ohc=J2O_NuF7Yy4AX8gAOhr&_nc_ht=cdn.fbsbx.com&oh=e804f15b4a62fa49f676fbb3b86f9626&oe=5F6BE9EE'
          } }
        ]
      end
      it { should be(true) }
    end
  end
end
