# frozen_string_literal: true

module ColorHelper
  COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'].freeze

  def color_from_id(id)
    COLORS[id % COLORS.length]
  end
end
