# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorThreemaSettings::ContributorThreemaSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) do
    create(:contributor,
           first_name: 'Max',
           last_name: 'Mustermann',
           threema_id: '12345678',
           created_at: '2021-01-01')
  end
  let(:threema) { instance_double(Threema) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }
  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
    allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
  end

  let(:params) { { contributor: contributor } }

  it { should have_css('h2', text: 'Threema') }
  it { should have_css('p', text: 'Max Mustermann hat sich unter der folgenden Threema-ID angemeldet.') }

  it { should have_css("form[action='/contributors/#{contributor.id}']") }
  it { should have_css('input[name="contributor[threema_id]"][value="12345678"]') }
  it { should have_css('button', text: 'Speichern') }
end
