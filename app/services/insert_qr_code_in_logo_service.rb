require 'open-uri'

class InsertQrCodeInLogoService
  def self.call(order, qr_code_id, qr_code_url, version, color)
    new(order, qr_code_id, qr_code_url, version, color).call
  end

  def initialize(order, qr_code_id, qr_code_url, version, color)
    @order = order
    @qr_code_id = qr_code_id
    @qr_code_url = qr_code_url
    @version = version
    @color = color
  end

  def call
    logo = MiniMagick::Image.open(back_asset)
    qr_code_image = MiniMagick::Image.read(URI.open(qr_code_url))

    if version == 'signature'
      qr_code_image.resize "740"

      result = logo.composite(qr_code_image) do |c|
        c.compose "Over"
        c.geometry "+65+65"
      end
    else

    # Create a new image with combined height
    combined_height = logo.height + qr_code_image.height
    max_width = [logo.width, qr_code_image.width].max

      # 3. Create a blank canvas using MiniMagick::Tool::Convert
      canvas_path = nil
      Tempfile.create(['canvas', '.png']) do |temp_file|
        canvas_path = temp_file.path

        # Create the blank white canvas
        MiniMagick::Tool::Convert.new do |convert|
          convert.size "#{max_width}x#{combined_height}"
          convert << "canvas:transparent"
          convert << canvas_path
        end

        # 4. Load the canvas as a MiniMagick::Image object
        result = MiniMagick::Image.open(canvas_path)

        # 5. Composite the first image at the top
        result = result.composite(qr_code_image) do |c|
          c.compose "Over"
          c.geometry "+0+0"
        end

        # 6. Composite the second image below the first
        result = result.composite(logo) do |c|
          c.compose "Over"
          c.geometry "+0+#{qr_code_image.height}"
        end
      end
    end

    file = Tempfile.new(["logo_with_qr_#{qr_code_id}", ".png"], Rails.root.to_s)
    result.write(file.path)
    file.rewind

    order.qr_code.attach(
      io: file,
      filename: "logo_with_qr_#{qr_code_id}.png",
      content_type: "image/png"
    )
  end

  private

  attr_reader :qr_code_url, :qr_code_id, :version, :color

  attr_accessor :order

  def back_asset
    if version == 'signature'
      return "app/assets/images/logo_full_white.png" if color == 'black'

      return "app/assets/images/logo_full_black.png" if color == 'white'
    else
      return "app/assets/images/tagline_white_no_bg.png" if color == 'black'

      return "app/assets/images/tagline_black_no_bg.png" if color == 'white'
    end
  end
end
