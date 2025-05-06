require 'faraday'
require 'faraday/multipart'
require 'json'

class PrintfulService
  BASE_URL = "https://api.printful.com"

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  # ⬇️ Upload direct d'un fichier binaire
  def upload_file(file_io, filename, content_type = "image/png")
    payload = {
      file: Faraday::Multipart::FilePart.new(file_io, content_type, filename),
      purpose: "default"
    }

    response = @conn.post('/files', payload)

    if response.success?
      json = JSON.parse(response.body)
      json.dig("result", "id")
    else
      raise "Erreur upload fichier Printful : #{response.status} - #{response.body}"
    end
  end

  # ⬇️ Upload spécifique du QR code attaché à un modèle Order
  def upload_qr_code(order)
    unless order.qr_code.attached?
      raise "QR code non attaché à la commande"
    end

    blob = order.qr_code.blob
    file_io = StringIO.new(blob.download)
    upload_file(file_io, blob.filename.to_s, blob.content_type)
  end

  # ⬇️ Envoi d'une commande Printful
  def create_order(order_data)
    response = @conn.post('/orders') do |req|
      req.headers['Authorization'] = "Bearer #{ENV['PRINTFUL_API_KEY']}"
      req.headers['Content-Type'] = 'application/json'
      req.body = order_data.to_json
    end

    if response.success?
      JSON.parse(response.body)
    else
      { error: "Erreur lors de la création de la commande: #{response.status} - #{response.body}" }
    end
  rescue Faraday::ConnectionFailed => e
    { error: "Connexion échouée : #{e.message}" }
  rescue Faraday::TimeoutError => e
    { error: "Délai d'attente dépassé : #{e.message}" }
  rescue StandardError => e
    { error: "Une erreur inattendue est survenue : #{e.message}" }
  end
end
