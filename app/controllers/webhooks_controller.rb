class WebhooksController < ApplicationController
  protect_from_forgery with: :null_session

  def shopify_order_paid
    request.body.rewind
    data = request.body.read
    hmac_header = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    secret = Rails.application.credentials.shopify[:api_secret]

    calculated_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', secret, data)
    )

    if ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
      # Webhook is verified, process the data
      head :ok
    else
      # Verification failed
      head :unauthorized
    end
  end

  private
end
