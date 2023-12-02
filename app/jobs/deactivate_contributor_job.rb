# frozen_string_literal: true

# frozen_string_literal: true, frozen

class DeactivateContributorJob < ApplicationJob
  queue_as :deactivate_contributor

  def perform(contributor_id:); end
end
