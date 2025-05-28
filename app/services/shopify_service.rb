class ShopifyService
  def self.call(request_body, request_headers)
    new(request_body, request_headers).call
  end

  def initialize(request_body, request_headers)
    @request_body = request_body
    @request_headers = request_headers
  end

  def call
    return :unauthorized unless verified?

    :ok
  end

  attr_reader :request_body, :request_headers

  private

  def verified?
    hmac_header = request_headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    secret = ENV['SHOPIFY_WEBHOOK_SECRET']

    calculated_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', secret, request_body)
    )

    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
  end
end
