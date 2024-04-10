# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileHeader::ProfileHeader, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contact_person) { create(:user, first_name: 'ContactFor', last_name: 'Organization') }
  let(:organization) do
    create(:organization,
           business_plan: editorial_basic,
           contact_person: contact_person)
  end
  let(:editorial_basic) { create(:business_plan, :editorial_basic, valid_from: Time.current, valid_until: 6.months.from_now) }
  let(:editorial_pro) { create(:business_plan, :editorial_pro) }
  let(:editorial_enterprise) { create(:business_plan, :editorial_enterprise) }
  let(:business_plans) { [editorial_basic, editorial_pro, editorial_enterprise] }
  let(:params) { { organization: organization, business_plans: business_plans } }

  it { is_expected.to have_css('.ProfileHeader') }
  it { is_expected.to have_text('Editorial Basic') }
  it { is_expected.to have_selector(:element, 'h2', 'data-testid': 'contact_person', text: 'ContactFor Organization') }

  it {
    expect(subject).to have_selector(:element, 'h2', 'data-testid': 'price_per_month',
                                                     text: number_to_currency(organization.business_plan.price_per_month).to_s)
  }

  it {
    expect(subject).to have_selector(:element, 'h2', 'data-testid': 'valid_until',
                                                     text: I18n.l(organization.business_plan.valid_until, format: '%m/%Y').to_s)
  }

  it {
    expect(subject).to have_button("Plan jetzt upgraden und #{organization.upgrade_discount}% sparen")
  }

  context 'No contact person' do
    before { organization.update!(contact_person: nil) }

    it { is_expected.to have_css('.ProfileHeader') } # doesn't crash with NilError
    it { is_expected.not_to have_selector(:element, 'h2', 'data-testid': 'contact_person') }
  end

  context 'Price with discount' do
    before { organization.update!(upgraded_business_plan_at: 5.minutes.ago) }

    let(:price_with_discount) do
      number_to_currency(organization.business_plan.price_per_month -
      (organization.business_plan.price_per_month * organization.upgrade_discount / 100.to_f))
    end

    it {
      expect(subject).not_to have_selector(:element, 'h2', 'data-testid': 'price_per_month',
                                                           text: number_to_currency(organization.business_plan.price_per_month).to_s)
    }

    it {
      expect(subject).to have_selector(:element, 'h2', 'data-testid': 'price_per_month', text: price_with_discount)
    }
  end

  context 'No expiration of plan' do
    before { organization.business_plan.update!(valid_until: nil) }

    it { is_expected.not_to have_selector(:element, 'h2', 'data-testid': 'valid_until') }
  end

  context 'No upgrade available' do
    before { organization.update!(business_plan: editorial_enterprise) }

    it { is_expected.not_to have_button('upgrade_business_plan_button') }
  end
end
