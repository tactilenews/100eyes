# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorChannelSettings::ContributorChannelSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor, email: nil, **attrs) }
  let(:attrs) { {} }
  let(:params) { { contributor: contributor } }

  it { should_not have_css('h2') }

  context 'given an email contributor' do
    let(:attrs) { { email: 'mustermann@example.org' } }
    it { should have_css('h2', text: 'via E-Mail') }
  end

  context 'given a Telegram contributor' do
    let(:attrs) { { telegram_id: 12_345_678 } }
    it { should have_css('h2', text: 'via Telegram') }
  end

  context 'given a Threema contributor' do
    let(:attrs) { { threema_id: 12_345_678 } }
    it { should have_css('h2', text: 'via Threema') }
  end
end