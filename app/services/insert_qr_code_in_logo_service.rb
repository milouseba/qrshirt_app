require 'open-uri'

class InsertQrCodeInLogoService
  def self.call(qr_code_id, qr_code_url)
    new(qr_code_id, qr_code_url).call
  end

  def initialize(qr_code_id, qr_code_url)
    @qr_code_id = qr_code_id
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


def generate_qr_code
    qrcode = RQRCode::QRCode.new(@url)
    @png = qrcode.as_png(size: 300)

    @file = Tempfile.new(['qrcode', '.png'])
    @file.binmode
    @file.write(@png.to_s)
    @file.rewind
  end

  def attach_to_order
    @order.qr_code.purge if @order.qr_code.attached?
    @order.qr_code.attach(
      io: @file,
      filename: "qrcode-#{@order.id}.png",
      content_type: 'image/png'
    )
  end

  def generate_file_url
    # Pour bucket S3 privé
    rails_blob_url(@order.qr_code, host: "https://qrshirt-app-847380a4e9f9.herokuapp.com")

    # Pour S3 public, utilise ceci à la place :
    # Rails.application.routes.url_helpers.rails_blob_url(@order.qr_code, only_path: false)
  end