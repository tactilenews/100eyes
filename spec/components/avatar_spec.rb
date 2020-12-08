# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  include Rails.application.routes.url_helpers
  let(:params) { {} }
  let(:component) { render_inline(described_class.new(**params)) }

  describe 'img' do
    subject { component.css('img') }

    describe 'given contributor without attached avatar' do
      let(:contributor) { build(:contributor, avatar: nil) }
      let(:params) { { contributor: contributor } }
      it { should be_empty }
    end
  end

  describe 'img[src]' do
    subject { component.css('img').first['src'] }

    describe 'given a contributor with attached avatar' do
      let(:contributor) { build(:contributor, :with_an_avatar) }
      let(:params) { { contributor: contributor } }

      it { should eq(rails_blob_path(contributor.avatar, only_path: true)) }
    end
  end

  describe '.Avatar-initials[style]' do
    subject { component.css('.Avatar-initials')[0][:style] }

    describe 'given a contributor' do
      let(:contributor) { build(:contributor, id: 0) }
      let(:params) { { contributor: contributor } }

      it { should start_with('--avatar-color: ') }
    end
  end

  describe '.Avatar-initials > text' do
    subject { component.css('.Avatar-initials > text').text }

    describe 'given a contributor without name' do
      let(:contributor) { build(:contributor, first_name: nil, last_name: nil) }
      let(:params) { { contributor: contributor } }
      it { should eq('?') }
    end

    describe 'given a contributor called "Zora"' do
      let(:contributor) { build(:contributor, first_name: 'Zora', last_name: nil) }
      let(:params) { { contributor: contributor } }
      it { should eq('Z') }
    end

    describe 'given a contributor called "Zora Ackermann"' do
      let(:contributor) { build(:contributor, first_name: 'Zora', last_name: 'Ackermann') }
      let(:params) { { contributor: contributor } }
      it { should eq('ZA') }
    end

    describe 'given a contributor called "Vicco von Bülow"' do
      let(:contributor) { build(:contributor, first_name: 'Vicco', last_name: 'von Bülow') }
      let(:params) { { contributor: contributor } }
      it { should eq('VvB') }
    end
  end
end
