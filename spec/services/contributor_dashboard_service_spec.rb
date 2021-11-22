# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorDashboardService, type: :service do
  let(:params) { ActionController::Parameters.new }
  let(:service) { -> { described_class.call params } }
  let(:subject) { service.call }

  context 'without contributors' do
    it 'returns empty list' do
      should eq []
    end
  end

  context 'given some contributors' do
    before do
      create(:contributor, first_name: 'Martin', last_name: 'Semmelrogge')
      create(:contributor, first_name: 'Klaus', last_name: 'Kinski')
      create(:contributor, first_name: 'Götz', last_name: 'George')
      create(:contributor, first_name: 'Manfred', last_name: 'Krug')
    end

    it 'returns contributors ordered alphabetically' do
      expect(subject.map(&:last_name)).to eq(%w[George Kinski Krug Semmelrogge])
    end

    describe 'when `order_direction` is set to `desc`' do
      let(:params) { ActionController::Parameters.new(order_direction: :desc) }

      it 'returns contributors ordered alphabetically in descending order' do
        expect(subject.map(&:last_name)).to eq(%w[Semmelrogge Krug Kinski George])
      end
    end
  end
end
