# frozen_string_literal: true

module QrCode
  class QrCode < ApplicationComponent
    MODULE_SIZE = 3

    def initialize(url:, **)
      super

      @qr_code = RQRCode::QRCode.new(url)
    end

    private

    def size
      @qr_code.modules.size * MODULE_SIZE
    end

    def svg_contents
      @qr_code.as_svg(standalone: false, use_path: true, module_size: MODULE_SIZE)
    end
  end
end
