require 'faraday'
require 'faraday/multipart'
require 'json'
require 'rest-client'

class PrintfulService
  BASE_URL = 'https://api.printful.com'.freeze

  SKU_TO_COLOR = {
    '9733786': 'white',
    '2908023': 'black',
    '6060554': 'white',
    '9664140': 'black',
    '2210068': 'white',
    '7011581': 'black',
    '2195347': 'white',
    '1211827': 'black',
  }

  SKU_TO_VERSION = {
    '9733786': 'signature',
    '2908023': 'signature',
    '6060554': 'impact',
    '9664140': 'impact',
    '2210068': 'signature',
    '7011581': 'signature',
    '2195347': 'impact',
    '1211827': 'impact',
  }

  # No longer needed as the Printful variant ID is the Shopify SKU' s last 5 digits
  SKU_TO_VARIANT = {
    '9733786_11576': 11576, '9733786_11577': 11577, '9733786_11578': 11578, '9733786_11579': 11579, '9733786_11580': 11580, # white signature tee
    '2908023_11546': 11546, '2908023_11547': 11547, '2908023_11548': 11548, '2908023_11549': 11549, '2908023_11550': 11550, # black signature tee
    '6060554_11576': 11576, '6060554_11577': 11577, '6060554_11578': 11578, '6060554_11579': 11579, '6060554_11580': 11580, # white impact tee
    '9664140_11546': 11546, '9664140_11547': 11547, '9664140_11548': 11548, '9664140_11549': 11549, '9664140_11550': 11550, # black impact tee
    '2210068_10774': 10774, '2210068_10775': 10775, '2210068_10776': 10776, '2210068_10777': 10777, '2210068_10778': 10778, # white signature hoodie
    '7011581_10779': 10779, '7011581_10780': 10780, '7011581_10781': 10781, '7011581_10782': 10782, '7011581_10783': 10783, # black signature hoodie
    '2195347_10774': 10774, '2195347_10775': 10775, '2195347_10776': 10776, '2195347_10777': 10777, '2195347_10778': 10778, # white impact hoodie
    '1211827_10779': 10779, '1211827_10780': 10780, '1211827_10781': 10781, '1211827_10782': 10782, '1211827_10783': 10783, # black impact hoodie
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
    sku.last(5).to_i
  end

  def fabric_color(sku)
    SKU_TO_COLOR[sku.first(7).to_sym]
  end

  def version_type(sku)
    SKU_TO_VERSION[sku.first(7).to_sym]
  end
end
