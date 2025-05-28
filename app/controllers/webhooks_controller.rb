class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def shopify_order_paid
    request.body.rewind

    ShopifyService.call(request.body.read, request.headers)
  end
end
