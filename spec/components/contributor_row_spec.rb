# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorRow::ContributorRow, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:styles) { [] }
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, tag_list: 'Tag 1, Tag 2') }
  let(:params) { { organization: organization, contributor: contributor, styles: styles } }

  it { should have_css('.ContributorRow') }
  it { should have_text(contributor.name) }

  context 'when contributor uses one channel' do
    let(:contributor) { create(:contributor, email: 'mail@mail.com') }
    it { should have_text('via Email') }
  end

  context 'when contributor uses multiple channels' do
    let(:contributor) { create(:contributor, email: 'mail@mail.com', telegram_id: 42) }
    it { should have_text('via Email, Telegram') }
  end

  context 'if compact' do
    let(:styles) { [:compact] }

    it { should have_css('.ContributorRow--compact') }
    it { should have_css('.Avatar--small') }
    it { should_not have_css('.TagsList') }
  end
end
