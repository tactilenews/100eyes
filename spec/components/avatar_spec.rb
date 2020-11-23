# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  let(:params) { {} }
  let(:component) { render_inline(described_class.new(**params)) }

  describe 'img' do
    subject { component.css('img') }
    describe 'given no contributor' do
      it { should be_empty }
    end

    describe 'given contributor without `avatar_url`' do
      let(:params) { { contributor: build(:contributor, avatar_url: nil) } }
      it { should be_empty }
    end
  end

  describe 'img[src]' do
    subject { component.css('img').first['src'] }

    describe 'given a a contributor with `avatar_url`' do
      let(:params) { { contributor: build(:contributor, avatar_url: '/my-avatar.jpg') } }
      it { should eq('/my-avatar.jpg') }
    end
  end

  describe '.Avatar-initials[style]' do
    subject { component.css('.Avatar-initials')[0][:style] }

    describe 'given no contributor' do
      it { should be_empty }
    end

    describe 'given a contributor' do
      let(:contributor) { build(:contributor, id: 0) }
      let(:params) { { contributor: contributor } }

      it { should start_with('--avatar-color: ') }
    end
  end

  describe '.Avatar-initials > text' do
    subject { component.css('.Avatar-initials > text').text }

    describe 'given no contributor' do
      it { should eq('?') }
    end

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
