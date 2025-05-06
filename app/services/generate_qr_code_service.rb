require 'rqrcode'

class GenerateQrCodeService
  def initialize(content, size: 300)
    @content = content
    @size = size
  end

  def call
    begin
      qr = RQRCode::QRCode.new(@content)
      qr_code_image = qr.as_png(size: @size, border_modules: 4)

      qr_code_image.to_blob
    rescue StandardError => e
      # Log de l'erreur pour débogage
      Rails.logger.error("Erreur lors de la génération du QR code: #{e.message}")
      # Retourner nil ou lever une exception personnalisée si nécessaire
      nil
    end
  end
end