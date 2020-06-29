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

  describe 'img[alt]' do
    subject { component.css('img').first['alt'] }
    describe 'given a user called "Till Popaska" with an avatar url' do
      let(:params) { { user: build(:user, first_name: 'Till', last_name: 'Popaska', avatar_url: '/fallback-dog.jpg') } }
      it { should eq('Till Popaska\'s avatar') }
    end
  end

  describe 'span.Avatar-initials' do
    subject { component.css('span.Avatar-initials').text }
    describe 'given no user' do
      it { should eq('?') }
    end

    describe 'given a user without name' do
      let(:params) { { user: build(:user, first_name: nil, last_name: nil) } }
      it { should eq('?') }
    end

    describe 'given a user called "Till"' do
      let(:params) { { user: build(:user, first_name: 'Till', last_name: nil) } }
      it { should eq('T') }
    end

    describe 'given a user called "Till Popaska"' do
      let(:params) { { user: build(:user, first_name: 'Till', last_name: 'Popaska') } }
      it { should eq('TP') }
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
