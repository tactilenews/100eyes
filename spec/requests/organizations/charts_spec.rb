# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Charts' do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organizations: [organization]) }
  let(:last_friday_midnight) { Time.zone.today.beginning_of_day.prev_occurring(:friday) }
  let(:request) { create(:request, broadcasted_at: last_friday_midnight, organization: organization) }
  let(:message) { create(:message, created_at: last_friday_midnight, request: request) }
  let(:data) do
    [
      { x: '00:00', y: 0 },
      { x: '01:00', y: 0 },
      { x: '02:00', y: 0 },
      { x: '03:00', y: 0 },
      { x: '04:00', y: 0 },
      { x: '05:00', y: 0 },
      { x: '06:00', y: 0 },
      { x: '07:00', y: 0 },
      { x: '08:00', y: 0 },
      { x: '09:00', y: 0 },
      { x: '10:00', y: 0 },
      { x: '11:00', y: 0 },
      { x: '12:00', y: 0 },
      { x: '13:00', y: 0 },
      { x: '14:00', y: 0 },
      { x: '15:00', y: 0 },
      { x: '16:00', y: 0 },
      { x: '17:00', y: 0 },
      { x: '18:00', y: 0 },
      { x: '19:00', y: 0 },
      { x: '20:00', y: 0 },
      { x: '21:00', y: 0 },
      { x: '22:00', y: 0 },
      { x: '23:00', y: 0 }
    ].freeze
  end
  let(:data_dup) { data.dup.map(&:dup) }
  let(:friday) { series.find { |hash| hash[:name] == 'Freitag' } }
  let(:series) do
    I18n.t('date.day_names').reverse.rotate(-1).map do |day|
      { name: day, data: data }
    end
  end

  describe 'GET /:organization_id/charts/day-and-time-replies' do
    before do
      message
      data_dup.first[:y] = 1
      friday[:data] = data_dup
    end

    subject { -> { get organization_charts_day_and_time_replies_path(organization, as: user) } }

    it 'responds with a series of each day and inbound grouped messages' do
      subject.call
      expect(response.body).to eq(series.to_json)
    end
  end

  describe 'GET /:organization_id/charts/day-and-time-requests' do
    subject { -> { get organization_charts_day_and_time_requests_path(organization, as: user) } }

    context 'no request, no chat messages' do
      before { series.map { |hash| hash[:data] = [] } }

      it 'returns empty data array' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end

    context 'request, no chat messages' do
      before do
        request
        data_dup.first[:y] = 1
        friday[:data] = data_dup
      end

      it 'responds with a series of each day and outbound grouped messages' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end

    context 'request, with chat message' do
      before do
        request
        message.update(broadcasted: false, sender: user, text: 'ChatMessage')
        data_dup.first[:y] = 2
        friday[:data] = data_dup
      end

      it 'responds with a series of each day and outbound grouped messages' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end
  end

  describe 'GET /:organization_id/charts/day-requests-replies' do
    subject { -> { get organization_charts_day_requests_replies_path(organization, as: user) } }
    let(:data) do
      I18n.t('date.day_names').rotate(1).map do |day|
        { x: day, y: 0 }
      end
    end
    let(:series) do
      [{ name: I18n.t('shared.community'), data: data },
       { name: I18n.t('shared.editorial'), data: data }]
    end

    context 'no requests, no replies' do
      it 'returns empty data array' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end

    context 'request, no replies' do
      let(:editorial) { series.find { |hash| hash[:name] == 'Redaktion' } }
      let(:friday) { data_dup.find { |hash| hash[:x] == 'Freitag' } }

      before do
        request
        friday[:y] = 1
        editorial[:data] = data_dup
      end

      it 'responds with a series of each day and outbound grouped messages' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end

    context 'request and replies' do
      let(:editorial) { series.find { |hash| hash[:name] == 'Redaktion' } }
      let(:community) { series.find { |hash| hash[:name] == 'Community' } }
      let(:friday) { data_dup.find { |hash| hash[:x] == 'Freitag' } }

      before do
        request
        message
        friday[:y] = 1
        editorial[:data] = data_dup
        community[:data] = data_dup
      end

      it 'responds with a series of each day and outbound grouped messages' do
        subject.call
        expect(response.body).to eq(series.to_json)
      end
    end
  end
end
