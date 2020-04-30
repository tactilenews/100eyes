# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Avatar::Avatar, type: :component do
  subject { render_inline(described_class.new(**params)) }

  describe 'given a url' do
    let(:params) { { url: '/my-avatar.jpg' } }
    it { should have_css('.Avatar > img[alt=""]') }
    it { should have_css('.Avatar > img[src="/my-avatar.jpg"]') }
  end

  describe 'without a url' do
    let(:params) { {} }

    it 'shows fallback images' do
      expect(subject.css('img').first['src']).to eq('/avatars/fallback-cat.jpg')
    end

    describe 'given different keys' do
      let(:first_avatar) { render_inline(described_class.new(key: 0)) }
      let(:other_avatar) { render_inline(described_class.new(key: 1)) }

      it 'shows different fallback images' do
        expect(first_avatar.css('img').first['src']).to eq('/avatars/fallback-cat.jpg')
        expect(other_avatar.css('img').first['src']).to eq('/avatars/fallback-dog.jpg')
      end
    end
  end
end
