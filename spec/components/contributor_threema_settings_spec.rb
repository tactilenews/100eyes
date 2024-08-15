# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorThreemaSettings::ContributorThreemaSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) do
    create(:contributor,
           :skip_validations,
           first_name: 'Max',
           last_name: 'Mustermann',
           threema_id: '12345678',
           created_at: '2021-01-01',
           organization: organization)
  end
  let(:params) { { contributor: contributor, organization: organization } }

  it { should have_css('h2', text: 'Threema') }
  it { should have_css('p', text: 'Max Mustermann hat sich unter der folgenden Threema-ID angemeldet.') }

  it { should have_css("form[action='/#{contributor.organization_id}/contributors/#{contributor.id}']") }
  it { should have_css('input[name="contributor[threema_id]"][value="12345678"]') }
  it { should have_css('button', text: 'Speichern') }
end
