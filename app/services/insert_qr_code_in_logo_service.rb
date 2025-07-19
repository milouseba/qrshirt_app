require 'open-uri'

class InsertQrCodeInLogoService
  def self.call(qr_code_url)
    new(qr_code_url).call
  end

  def initialize(qr_code_url)
    @qr_code_url = qr_code_url
  end

  def call
    logo = MiniMagick::Image.open("app/assets/images/logo_blanc.png")
    qr_code_image = MiniMagick::Image.read(URI.open(qr_code_url))

    qr_code_image.resize "535x535"

    # puis les fusionner (overlay)
    result = logo.composite(qr_code_image) do |c|
      c.compose "Over"    # mode de composition
      c.geometry "+390+680"   # position où placer image2 sur image1
    end

    result.write("public/logo_with_qr.png")
  end

  private

  attr_reader :qr_code_url
end
