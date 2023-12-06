# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastRequestJob do
  describe '#perform_later(request_id:)' do
    subject { -> { described_class.new.perform(request_id: request.id) } }

    let!(:contributor) { create(:contributor) }
    let(:request) { create(:request, broadcasted_at: nil) }

    context 'given the request has been deleted' do
      before { request.destroy }

      it 'does not rails an error' do
        expect { subject.call }.not_to raise_error
      end

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end
    end

    context 'given a request has been broadcast' do
      before { request.update(broadcasted_at: 5.minutes.ago) }

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'does not update the broadcasted_at attr' do
        expect { subject.call }.not_to(change { request.reload.broadcasted_at })
      end
    end

    context 'given a request has been rescheduled for the future' do
      before { request.update(schedule_send_for: 1.day.from_now) }
      let(:expected_params) { { request_id: request.id } }

      it 'enqueues a job to broadcast the request, and broadcast it when called again' do
        expect { subject.call }.to change(DelayedJob, :count).from(0).to(1)
        expect(Delayed::Job.last.run_at).to be_within(1.second).of(request.schedule_send_for)

        Timecop.travel(1.day.from_now + 2.minutes)

        expect { subject.call }.to change { request.reload.broadcasted_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it 'does not create a Message instance' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'does not update the broadcasted_at attr' do
        expect { subject.call }.not_to(change { request.reload.broadcasted_at })
      end
    end
  end
end
