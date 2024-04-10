# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestForm::RequestForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request: build(:request) } }

  it { is_expected.to have_css('.RequestForm') }

  it {
    expect(subject).not_to have_css('button[data-action="request-form#openModal"]',
                                    text: I18n.t('components.request_form.planned_request.destroy.button_text'))
  }

  context 'planned request' do
    let(:params) { { request: create(:request, broadcasted_at: nil, schedule_send_for: 1.day.from_now) } }

    it 'renders a button to open a confirm destroy modal' do
      expect(subject).to have_css('button[data-action="request-form#openModal"]',
                                  text: I18n.t('components.request_form.planned_request.destroy.button_text'))
    end

    it 'renders a destroy planned request modal' do
      expect(subject).to have_css('.DestroyPlannedRequestModal')
    end
  end
end
