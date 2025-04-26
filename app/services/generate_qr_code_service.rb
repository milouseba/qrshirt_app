require 'rqrcode'

class GenerateQrCodeService
  def initialize(content)
    @content = content
  end

  def call
    qr = RQRCode::QRCode.new(@content)
    qr.as_png(size: 300, border_modules: 4)
  end
end