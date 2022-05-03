# frozen_string_literal: true

module Admin
  class ContributorsController < Admin::ApplicationController
    include AdministrateExportable::Exporter
  end
end
