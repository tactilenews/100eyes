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
      semmelrogge = create(:contributor, first_name: 'Martin', last_name: 'Semmelrogge')
      kinski = create(:contributor, first_name: 'Klaus', last_name: 'Kinski')
      george = create(:contributor, first_name: 'Götz', last_name: 'George')
      create(:contributor, first_name: 'Manfred', last_name: 'Krug')

      create(:message, sender: george)
      create(:message, recipient: kinski, sender: nil)
      create(:message, sender: semmelrogge)
    end

    describe 'by default' do
      it 'returns contributors ordered alphabetically' do
        expect(subject.map(&:last_name)).to eq(%w[George Kinski Krug Semmelrogge])
      end
    end

    describe 'when `order_direction` is set to `desc`' do
      let(:params) { ActionController::Parameters.new(order_direction: :desc) }

      it 'returns contributors ordered alphabetically in descending order' do
        expect(subject.map(&:last_name)).to eq(%w[Semmelrogge Krug Kinski George])
      end
    end

    describe 'when `order` is set to `activity`' do
      let(:params) { ActionController::Parameters.new(order: :activity) }

      it 'returns contributors ordered by most recent activity in ascending order' do
        expect(subject.map(&:last_name)).to eq(%w[Kinski Krug George Semmelrogge])
      end

      describe 'when `order_direction` is set to `desc`' do
        let(:params) { ActionController::Parameters.new(order: :activity, order_direction: :desc) }

        it 'returns contributors ordered by most recent activity in descending order' do
          expect(subject.map(&:last_name)).to eq(%w[Semmelrogge George Kinski Krug])
        end
      end
    end
  end
end
