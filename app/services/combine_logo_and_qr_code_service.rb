require 'open-uri'

class CombineImagesService

  def self.call(logo_path, qr_code_url)
    new(logo_path, qr_code_url).call
  end

  def initialize(logo_path, qr_code_url)
    @logo_path = logo_path
    @qr_code_url = qr_code_url
  end

  def call
    logo = MiniMagick::Image.open("assets/images/fichier_local.png")
    image2 = MiniMagick::Image.read(URI.open("https://example.com/ton_image.png"))

    # puis les fusionner (overlay)
    result = image1.composite(image2) do |c|
      c.compose "Over"    # mode de composition
      c.geometry "+X+Y"   # position où placer image2 sur image1
    end

    result.write("chemin/vers/le/fichier_final.png")
  end
end
