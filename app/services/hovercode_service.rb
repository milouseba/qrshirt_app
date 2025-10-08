require 'rest-client'
require 'json'

class HovercodeService
  ROOT_URL = 'https://hovercode.com/api/v2/'

  def create_qr_code(shopify_id, sku)
    endpoint = 'hovercode/create/'
    payload = {
                workspace: ENV['HOVERCODE_WORKSPACE_ID'],
                qr_data: Rails.application.routes.url_helpers.flash_qr_code_url(shopify_id),
                frame: frame(sku),
                error_correction: 'H',
                primary_color: primary_color(sku),
                has_border: false,
                dynamic: true,
                generate_png: true,
              }.to_json

    begin
      response = RestClient.post(ROOT_URL + endpoint, payload, headers)
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      puts "Error: #{e.response}"
    end
  end

  def get_qr_code(qr_code_id)
    endpoint = "hovercode/#{qr_code_id}"

    begin
      response = RestClient.get(ROOT_URL + endpoint, headers)
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      puts "Error: #{e.response}"
    end
  end

  private

  def headers
    {
      Content_Type: 'application/json',
      Authorization: "Token #{ENV['HOVERCODE_API_TOKEN']}"
    }
  end

  def primary_color(sku)
    PrintfulService.new.fabric_color(sku) == 'white' ? '#000000' : '#ffffff'
  end

  def frame(sku)
    PrintfulService.new.version_type(sku) == 'signature' ? 'round-frame' : nil
  end
end
