# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  include Rails.application.routes.url_helpers
  subject { component }

  let(:params) { { record: contributor } }
  let(:component) { render_inline(described_class.new(**params)) }

  describe 'img' do
    subject { component.css('img') }

    describe 'given contributor without attached avatar' do
      let(:contributor) { build(:contributor, avatar: nil) }

      it { is_expected.to be_empty }
    end
  end

  describe 'img[src]' do
    subject { component.css('img').first['src'] }

    describe 'given a contributor with attached avatar' do
      let(:contributor) { create(:contributor, :with_an_avatar) }

      it 'displays avatar thumbnail' do
        thumbnail = contributor.avatar.variant(resize_to_fit: [200, 200])
        url = rails_representation_url(thumbnail, only_path: true)

        expect(subject).to eq(url)
      end
    end
  end

  describe '.Avatar-initials[style]' do
    subject { component.css('.Avatar-initials')[0][:style] }

    describe 'given a contributor' do
      let(:contributor) { build(:contributor, id: 0) }

      it { is_expected.to start_with('--avatar-color: ') }
    end
  end

  describe '.Avatar-initials > text' do
    subject { component.css('.Avatar-initials > text').text }

    describe 'given a contributor without name' do
      let(:contributor) { build(:contributor, first_name: nil, last_name: nil) }

      it { is_expected.to eq('?') }
    end

    describe 'given a contributor called "Zora"' do
      let(:contributor) { build(:contributor, first_name: 'Zora', last_name: nil) }

      it { is_expected.to eq('Z') }
    end

    describe 'given a contributor called "Zora Ackermann"' do
      let(:contributor) { build(:contributor, first_name: 'Zora', last_name: 'Ackermann') }

      it { is_expected.to eq('ZA') }
    end

    describe 'given a contributor called "Vicco von Bülow"' do
      let(:contributor) { build(:contributor, first_name: 'Vicco', last_name: 'von Bülow') }

      it { is_expected.to eq('VvB') }
    end
  end

  describe 'link' do
    context 'given a contributor without an avatar' do
      let(:contributor) { build(:contributor, avatar: nil) }

      it { is_expected.not_to have_css('.Avatar a') }

      context 'if it is expandable' do
        let(:params) { { record: contributor, expandable: true } }

        it { is_expected.not_to have_css('.Avatar a') }
      end
    end

    context 'given a contributor with an avatar' do
      let(:contributor) { create(:contributor, :with_an_avatar) }

      it { is_expected.not_to have_css('.Avatar a') }

      context 'if it is expandable' do
        let(:params) { { record: contributor, expandable: true } }

        it { is_expected.to have_css('.Avatar a[aria-label="In Originalgröße anzeigen"]') }
      end
    end
  end
end
