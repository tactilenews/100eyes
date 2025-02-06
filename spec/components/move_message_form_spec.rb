# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveMessageForm::MoveMessageForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let!(:older_request) { create(:request, broadcasted_at: 1.hour.ago, organization: organization) }
  let!(:request_for_info) { create(:request, broadcasted_at: 0.hours.ago, organization: organization) }
  let!(:planned_request) { create(:request, broadcasted_at: 1.hour.from_now, organization: organization) }
  let!(:other_organizations_request) { create(:request, broadcasted_at: 1.hour.ago) }

  let(:message) { create(:message, request: request_for_info, organization: organization) }

  let(:params) { { message: message } }

  it { should have_css('form') }

  it 'renders a radio input for the two requests and an option for no request' do
    expect(subject).to have_css('input[type="radio"]', count: 3)
    organization.requests.each do |request|
      expect(subject).to have_css(:strong, text: request.title)
    end
    expect(subject).to have_css(:strong, text: 'Gehört zu keiner Frage')
  end

  it 'displays current request checked' do
    first = subject.css('input[type="radio"]').first

    expect(first[:value]).to eq(request_for_info.id.to_s)
    expect(first[:checked]).to eq('checked')
  end

  it 'displays older request unchecked' do
    older_request_input = subject.css('input[type="radio"]').select { |input| input[:value].eql?(older_request.id.to_s) }.first

    expect(older_request_input[:checked]).to be_nil
  end

  it 'displays option to remove request unchecked' do
    no_request_input = subject.css('input[type="radio"]').select { |input| input[:value].eql?('') }.first

    expect(no_request_input[:checked]).to be_nil
  end

  it 'does not show planned request' do
    request_ids = subject.css('input[type="radio"]').pluck(:value)
    expect(request_ids).not_to include(planned_request.id.to_s)
  end

  it 'does not show other organizations request' do
    request_ids = subject.css('input[type="radio"]').pluck(:value)
    expect(request_ids).not_to include(other_organizations_request.id.to_s)
  end
end
