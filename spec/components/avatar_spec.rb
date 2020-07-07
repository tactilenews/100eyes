# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  let(:params) { {} }
  let(:component) { render_inline(described_class.new(**params)) }

  describe 'img' do
    subject { component.css('img') }
    describe 'given no user' do
      it { should be_empty }
    end

    describe 'given user without `avatar_url`' do
      let(:params) { { user: build(:user, avatar_url: nil) } }
      it { should be_empty }
    end
  end

  describe '.Avatar-initials > text' do
    subject { component.css('.Avatar-initials > text').text }
    describe 'given no user' do
      it { should eq('?') }
    end

    describe 'given a user without name' do
      let(:user) { build(:user, first_name: nil, last_name: nil) }
      let(:params) { { user: user } }
      it { should eq('?') }
    end

    describe 'given a user called "Zora"' do
      let(:user) { build(:user, first_name: 'Zora', last_name: nil) }
      let(:params) { { user: user } }
      it { should eq('Z') }
    end

    describe 'given a user called "Zora Ackermann"' do
      let(:user) { build(:user, first_name: 'Zora', last_name: 'Ackermann') }
      let(:params) { { user: user } }
      it { should eq('ZA') }
    end

    describe 'given a user called "Vicco von Bülow"' do
      let(:user) { build(:user, first_name: 'Vicco', last_name: 'von Bülow') }
      let(:params) { { user: user } }
      it { should eq('VvB') }
    end
  end

  describe 'img[src]' do
    subject { component.css('img').first['src'] }

    describe 'given a a user with `avatar_url`' do
      let(:params) { { user: build(:user, avatar_url: '/my-avatar.jpg') } }
      it { should eq('/my-avatar.jpg') }
    end
  end
end
