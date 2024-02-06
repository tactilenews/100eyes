# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message::File, type: :model do
  describe '::counter_culture_fix_counts' do
    subject do
      described_class.counter_culture_fix_counts
      message.reload
    end

    context 'given the photos count has become invalid for whatever reason' do
      let(:request) { create(:request) }

      describe 'counts images of replies' do
        let(:message) { create(:message, :with_file, request: request, attachment: fixture_file_upload('example-image.png')) }
        before { message.update(photos_count: 4711) }
        it { expect { subject }.to (change { message.photos_count }).from(4711).to(1) }
      end

      describe 'does not count other content types' do
        let(:message) { create(:message, :with_file, request: request, attachment: fixture_file_upload('example-audio.oga')) }
        before { message.update(photos_count: 4711) }
        it { expect { subject }.to (change { message.photos_count }).from(4711).to(0) }
      end

      describe 'does not count non-replies' do
        let(:message) { create(:message, :with_file, :outbound, request: request, attachment: fixture_file_upload('example-image.png')) }
        before { message.update(photos_count: 4711) }
        it { expect { subject }.to (change { message.photos_count }).from(4711).to(0) }
      end
    end
  end
end
