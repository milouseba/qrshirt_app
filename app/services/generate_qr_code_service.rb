require 'rqrcode'
require 'chunky_png'

class GenerateQrCodeService
  include Rails.application.routes.url_helpers

  # Génère un QR code à partir d'une URL et l'attache à un modèle Order
  # Retourne l'URL utilisable par Printful
  def self.call(order, url)
    new(order, url).call
  end

  def initialize(order, url)
    @order = order
    @url = url
  end

  def call
    generate_qr_code
    attach_to_order
    generate_file_url
  ensure
    cleanup_tempfile
  end

  private

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

  def cleanup_tempfile
    return unless @file

    @file.close
    @file.unlink
  end
end
