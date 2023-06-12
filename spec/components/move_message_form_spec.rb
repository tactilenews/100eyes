# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveMessageForm::MoveMessageForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let!(:older_request) { create(:request, broadcasted_at: 1.hour.ago) }
  let!(:current_request) { create(:request, broadcasted_at: 0.hours.ago) }
  let!(:planned_request) { create(:request, broadcasted_at: 1.hour.from_now) }

  let(:message) { create(:message, request: current_request) }

  let(:params) { { message: message } }

  it { should have_css('form') }
  it { should have_css('input[type="radio"]', count: 2) }

  it 'displays current request checked' do
    first = subject.css('input[type="radio"]').first

    expect(first[:value]).to eq(current_request.id.to_s)
    expect(first[:checked]).to eq('checked')
  end

  it 'displays older request unchecked' do
    last = subject.css('input[type="radio"]').last

    expect(last[:value]).to eq(older_request.id.to_s)
    expect(last[:checked]).to be_nil
  end

  it 'does not show planned request' do
    request_ids = subject.css('input[type="radio"]').pluck(:value)
    expect(request_ids).not_to include(planned_request.id)
  end
end
