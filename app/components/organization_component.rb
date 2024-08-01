class OrganizationComponent < ApplicationComponent
  delegate :organization, to: :helpers
end
