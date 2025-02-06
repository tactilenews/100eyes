# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class SetProfileInfoJob < ApplicationJob
      def perform(organization_id:); end
    end
  end
end
