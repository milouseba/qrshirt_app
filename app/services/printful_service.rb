require 'faraday'
require 'faraday/multipart'
require 'json'
require 'rest-client'

class PrintfulService
  BASE_URL = 'https://api.printful.com'.freeze
  SKU_TO_VARIANT = {
    '9733786_11576': 4011, '9733786_11577': 4012, '9733786_11578': 4013, '9733786_11579': 4014, '9733786_11580': 4015,
    '2908023_11546': 4016, '2908023_11547': 4017, '2908023_11548': 4018, '2908023_11549': 4019, '2908023_11550': 4020,
  }

  # Not used - can be removed
  PRODUCT_ID = 71 # ID du t-shirt Unisex dans l'API Printful
  VARIANTS_IDS = {
    'White' => { 'XS' => 9526, 'S' => 4011, 'M' => 4012, 'L' => 4013, 'XL' => 4014, 'XXL' => 4015, '3XL' => 5294, '4XL' => 5309, '5XL' => 12872},
    'Black' => { 'XS' => 9527, 'S' => 4016, 'M' => 4017, 'L' => 4018, 'XL' => 4019, 'XXL' => 4020, '3XL' => 5295, '4XL' => 5310, '5XL' => 12871},
  }

  def initialize(api_key = ENV['PRINTFUL_API_KEY'])
    @api_key = api_key
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  # ⬇️ Envoi d'une commande Printful
  def create_order(order_data)
    response = @conn.post('/orders?store_id=15916712&confirm=true') do |req|
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = order_data.to_json
    end

    if response.success?
      JSON.parse(response.body)
    else
      { 'error' => "Erreur lors de la création de la commande: #{response.status} - #{response.body}" }
    end
  rescue Faraday::ConnectionFailed => e
    { 'error' => "Connexion échouée : #{e.message}" }
  rescue Faraday::TimeoutError => e
    { 'error' => "Délai d'attente dépassé : #{e.message}" }
  rescue StandardError => e
    { 'error' => "Une erreur inattendue est survenue : #{e.message}" }
  end

  def confirm_order(order_id)
    response = @conn.post("/orders/#{order_id}/confirm") do |req|
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Store-Id'] = '15916712'
    end

    if response.success?
      JSON.parse(response.body)
    else
      { 'error' => "Erreur lors de la confirmation de la commande: #{response.status} - #{response.body}" }
    end
  rescue Faraday::ConnectionFailed => e
    { 'error' => "Connexion échouée : #{e.message}" }
  rescue Faraday::TimeoutError => e
    { 'error' => "Délai d'attente dépassé : #{e.message}" }
  rescue StandardError => e
    { 'error' => "Une erreur inattendue est survenue : #{e.message}" }
  end

  def create_file
    file_path = Rails.root.join("public", "logo_with_qr.png")

    payload = {
      files: File.new(file_path, 'rb')  # ✅ ENVOI D'UN ARRAY DE FICHIERS
    }

    Order.last.qr_code.attach(
      io: File.new(Rails.root.join("public", "logo_with_qr.png"), 'rb'),
      filename: "qrcode-#{Order.last.id}.png",
      content_type: 'image/png'
    )

    headers = {
      Authorization: "Bearer #{ENV['PRINTFUL_API_KEY']}"
    }

    response = RestClient.post("https://api.printful.com/files", payload, headers)

    puts "Status: #{response.code}"
    puts "Body: #{response.body}"
    JSON.parse(response.body)

  rescue RestClient::ExceptionWithResponse => e
    puts "Error: #{e.response.code}"
    puts "Response: #{e.response.body}"
    JSON.parse(e.response.body)
  end

  def update_order
    # fetch webhook and dispatch new order status to Shopify
    # find order in DB by external id
    # update order status with Shopify API
  end

  def variant_id(sku)
    SKU_TO_VARIANT[sku.to_sym]
  end

  def get_variant_id(color, size)
    # Mapping des couleurs et tailles aux variant_ids de Printful
    # Ces IDs doivent être ajustés selon les variants disponibles dans votre compte Printful
    variants = {
      'White' => { 'S' => 4011, 'M' => 4012, 'L' => 4013, 'XL' => 4014, 'XXL' => 4015 },
      'Black' => { 'S' => 4016, 'M' => 4017, 'L' => 4018, 'XL' => 4019, 'XXL' => 4020 },
      'Navy' => { 'S' => 4021, 'M' => 4022, 'L' => 4023, 'XL' => 4024, 'XXL' => 4025 },
      'Blue' => { 'S' => 4026, 'M' => 4027, 'L' => 4028, 'XL' => 4029, 'XXL' => 4030 },
      'Red' => { 'S' => 4031, 'M' => 4032, 'L' => 4033, 'XL' => 4034, 'XXL' => 4035 }
    }

    variants[color][size]
  end
end
