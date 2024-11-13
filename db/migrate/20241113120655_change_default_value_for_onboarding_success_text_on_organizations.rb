# frozen_string_literal: true

class ChangeDefaultValueForOnboardingSuccessTextOnOrganizations < ActiveRecord::Migration[6.1]
  # rubocop:disable Layout/LineLength
  def change
    change_column_default :organizations, :onboarding_success_text,
                          from: "Unsere Dialog-Recherche startet bald. Wir melden uns dann bei Ihnen.\n\nUm unseren Kanal Abzubestellen, schreibe „abbestellen“.\n",
                          to: "Unsere Dialog-Recherche startet bald. Wir melden uns dann bei Ihnen.\n\nUm unseren Kanal abzubestellen, schreibe „abbestellen“.\n"
  end
  # rubocop:enable Layout/LineLength
end
