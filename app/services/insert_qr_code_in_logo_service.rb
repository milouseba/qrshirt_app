require 'open-uri'

class InsertQrCodeInLogoService
  def self.call(order, qr_code_id, qr_code_url)
    new(order, qr_code_id, qr_code_url).call
  end

  def initialize(order, qr_code_id, qr_code_url)
    @order = order
    @qr_code_id = qr_code_id
    @qr_code_url = qr_code_url
  end

  def call
    logo = MiniMagick::Image.open("app/assets/images/logo_blanc.png")
    qr_code_image = MiniMagick::Image.read(URI.open(qr_code_url))

    qr_code_image.resize "535x535"

    result = logo.composite(qr_code_image) do |c|
      c.compose "Over"
      c.geometry "+390+680"
    end

    Tempfile.create(["logo_with_qr_#{qr_code_id}", ".png"]) do |file|
      result.write(file.path)
      file.rewind

      order.qr_code_id.attach(
        io: file,
        filename: "logo_with_qr_#{qr_code_id}.png",
        content_type: "image/png"
      )
    end
  end

  private

  attr_reader :qr_code_url, :qr_code_id

  attr_accessor :order
end
