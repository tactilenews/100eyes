# frozen_string_literal: true

module ColorHelper
  TAG_COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'].freeze

  def tag_color_from_id(tag_id)
    TAG_COLORS[tag_id % TAG_COLORS.length]
  end
end
