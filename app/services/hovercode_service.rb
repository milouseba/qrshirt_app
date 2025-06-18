require 'rest-client'
require 'json'

class HovercodeService
  ROOT_URL = 'https://hovercode.com/api/v2/'

  def initialize(url)
    @url = url
  end

  def create_qr_code
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

  attr_reader :url

  private

  def headers
    {
      Content_Type: 'application/json',
      Authorization: "Token #{ENV['HOVERCODE_API_TOKEN']}"
    }
  end

end
