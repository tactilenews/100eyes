# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message::WhatsAppTemplate do
  describe '#read_at=(datetime)' do
    subject do
      whats_app_template.read_at = read_at
      whats_app_template.save
    end

    let!(:whats_app_template) { create(:message_whats_app_template, message: create(:message), delivered_at: nil, read_at: nil) }
    let!(:read_at) { Time.zone.at(1_692_118_778).to_datetime }

    it 'updates both read_at and delivered_at, if blank, as you cannot read a template that has not been delivered' do
      expect { subject }.to (change { whats_app_template.reload.read_at }).from(nil).to(read_at)
                                                                          .and (change do
                                                                                  whats_app_template.reload.delivered_at
                                                                                end).from(nil).to(read_at)
    end

    context 'given delivered_at is present' do
      before { whats_app_template.update!(delivered_at: 1.day.ago) }

      it 'does not update it' do
        expect { subject }.not_to(change { whats_app_template.reload.delivered_at })
      end
    end
  end
end
