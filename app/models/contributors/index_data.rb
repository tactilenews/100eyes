# frozen_string_literal: true

module Contributors
  class IndexData
    def initialize(organization, contributors_params)
      @organization = organization
      @state = state_params(contributors_params)
      @tag_list = tag_list_params(contributors_params)

      @active_count = @organization.contributors.active.count
      @inactive_count = @organization.contributors.inactive.count
      @unsubscribed_count = @organization.contributors.unsubscribed.count
      @available_tags = @organization.contributors_tags_with_count.to_json

      @contributors = filtered_contributors(@state)
      @contributors = @contributors.with_tags(@tag_list)
      @filter_count = @contributors.size
      @contributors = @contributors.with_attached_avatar.includes(:tags).page(contributors_params[:page])
    end

    attr_reader :organization, :state, :tag_list, :active_count, :inactive_count, :unsubscribed_count, :available_tags, :contributors,
                :filter_count

    private

    def state_params(contributors_params)
      value = contributors_params[:state]&.to_sym

      return :active unless %i[active inactive unsubscribed].include?(value)

      value
    end

    def tag_list_params(contributors_params)
      value = contributors_params[:tag_list]
      return [] if value.blank? || value.all?(&:blank?)

      value.reject(&:empty?).first.split(',')
    end

    def filtered_contributors(state)
      case state
      when :inactive
        @organization.contributors.inactive
      when :unsubscribed
        @organization.contributors.unsubscribed
      else
        @organization.contributors.active
      end
    end
  end
end
