# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorThreemaSettings::ContributorThreemaSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) do
    build(:contributor,
          first_name: 'Max',
          last_name: 'Mustermann',
          threema_id: '12345678',
          created_at: '2021-01-01').tap { |contributor| contributor.save(validate: false) }
  end
  let(:params) { { contributor: contributor } }

  it { is_expected.to have_css('h2', text: 'Threema') }
  it { is_expected.to have_css('p', text: 'Max Mustermann hat sich unter der folgenden Threema-ID angemeldet.') }

  it { is_expected.to have_css("form[action='/contributors/#{contributor.id}']") }
  it { is_expected.to have_css('input[name="contributor[threema_id]"][value="12345678"]') }
  it { is_expected.to have_css('button', text: 'Speichern') }
end
