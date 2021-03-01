# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorRow::ContributorRow, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:contributor) { create(:contributor) }
  let(:params) { { contributor: contributor } }

  it { should have_css('.ContributorRow') }

  context 'when contributor uses one channel' do
    it { should have_text('via Email') }
  end

  context 'when contributor uses multiple channels' do
    let(:contributor) { create(:contributor, telegram_id: 42) }
    it { should have_text('via Email, Telegram') }
  end
end
