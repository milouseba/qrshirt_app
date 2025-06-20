require 'rest-client'
require 'json'

class HovercodeService
  ROOT_URL = 'https://hovercode.com/api/v2/'

  def create_qr_code(url)
    endpoint = 'hovercode/create/'
    payload = {
                workspace: ENV['HOVERCODE_WORKSPACE_ID'],
                qr_data: url,
              }.to_json

    begin
      response = RestClient.post(ROOT_URL + endpoint, payload, headers)
      JSON.parse(response.body)['id']
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

end
