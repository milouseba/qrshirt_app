require 'faraday'
require 'json'

class PrintfulService
  BASE_URL = "https://api.printful.com"

  def initialize
    @conn = Faraday.new(
      url: BASE_URL,
      headers: {
        'Authorization' => "Bearer #{ENV['PRINTFUL_API_KEY']}",
        'Content-Type' => 'application/json'
      }
    )
  end

  def create_order(order_data)
    response = @conn.post('/orders') do |req|
      req.body = order_data.to_json
    end
    JSON.parse(response.body)
  end
end