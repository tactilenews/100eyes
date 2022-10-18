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
    it { should have_css('h2', text: 'E-Mail') }
  end

  context 'given a Telegram contributor' do
    let(:attrs) { { telegram_id: 12_345_678 } }
    it { should have_css('h2', text: 'Telegram') }
  end

  context 'given a Threema contributor' do
    let(:threema) { instance_double(Threema) }
    let(:threema_lookup_double) { instance_double(Threema::Lookup) }
    before do
      allow(Threema).to receive(:new).and_return(threema)
      allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
      allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    end
    let(:attrs) { { threema_id: 12_345_678 } }
    it { should have_css('h2', text: 'Threema') }
  end

  context 'given a Signal contributor' do
    let(:attrs) { { signal_phone_number: '+49123456789' } }
    it { should have_css('h2', text: 'Signal') }
  end
end
