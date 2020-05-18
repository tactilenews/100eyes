# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  let(:params) { {} }
  let(:component) { render_inline(described_class.new(**params)) }

  describe 'img[alt]' do
    subject { component.css('img').first['alt'] }
    it { should eq('') }
  end

  describe 'img[src]' do
    subject { component.css('img').first['src'] }

    describe 'given no user' do
      let(:params) { {} }
      it { should eq('/avatars/fallback-cat.jpg') }
    end

    describe 'given a a user with `avatar_url`' do
      let(:params) { { user: build(:user, avatar_url: '/my-avatar.jpg') } }
      it { should eq('/my-avatar.jpg') }
    end

    describe 'given user without `avatar_url`' do
      describe 'id === 1' do
        let(:params) { { user: build(:user, id: 1) } }
        it { should eq('/avatars/fallback-dog.jpg') }
      end

      describe 'id === 2' do
        let(:params) { { user: build(:user, id: 2) } }
        it { should eq('/avatars/fallback-otter.jpg') }
      end
    end
  end
end
