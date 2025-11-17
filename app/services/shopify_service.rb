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

    response = JSON.parse(request_body)
    return if order_exists?(response)

    new_order = create_order(response)

    # generate dynamic QR code
    hovercode_service = HovercodeService.new

    # determine version and color
    sku = response['line_items'][0]['sku']
    printful_service = PrintfulService.new
    version = printful_service.version_type(sku)
    color = printful_service.fabric_color(sku)

    qr_code_payload = hovercode_service.create_qr_code(new_order.reload.shopify_id, sku)
    qr_code_id = qr_code_payload['id']
    new_order.update!(qr_code_id:)

    InsertQrCodeInLogoService.call(new_order, qr_code_id, qr_code_payload['png'], version, color)
    printable_image_url = Rails.application.routes.url_helpers.rails_blob_url(new_order.qr_code, only_path: false)
    # send asset to Printful and create + confirm order
    order_data = {
      external_id: new_order.id,
      recipient: {
        name: response['shipping_address']['name'],
        email: new_order.email,
        address1: response['shipping_address']['address1'],
        city: response['shipping_address']['city'],
        zip: response['shipping_address']['zip'],
        country: response['shipping_address']['country_code'],
      },
      items: [{
        variant_id: printful_service.variant_id(sku),
        quantity: new_order.quantity,
        files: [
          {url: printable_image_url, type: 'back'},

      # Signature back hoodie
      # "position": {
      #   "area_width": 2000,
      #   "area_height": 2000,
      #   "width": 2000,
      #   "height": 1287,
      #   "top": 0,
      #   "left": 0
      # }


      # Signature back t-shirt
      #       "position": {
      #   "area_width": 2000,
      #   "area_height": 2000,
      #   "width": 2000,
      #   "height": 1287,
      #   "top": 500,
      #   "left": 0
      # }


    # Impact front t-shirt
    #     {
    #   "placement": "front",
    #   "image_url": "https://qrshirt-app-847380a4e9f9.herokuapp.com/assets/logo_black_short-78ff386b313e70ee711113c788dd537f50fc66766e50f7a94106a738285bc074.png",
    #   "position": {
    #     "area_width": 2000,
    #     "area_height": 2000,
    #     "width": 400,
    #     "height": 284,
    #     "top": 300,
    #     "left": 1400
    #   }
    # }

    # Impact front hoodie
      # {
      #   "placement": "front",
      #   "image_url": "https://qrshirt-app-847380a4e9f9.herokuapp.com/assets/logo_black_short-78ff386b313e70ee711113c788dd537f50fc66766e50f7a94106a738285bc074.png",
      #   "position": {
      #     "area_width": 2000,
      #     "area_height": 2000,
      #     "width": 400,
      #     "height": 284,
      #     "top": 500,
      #     "left": 1400
      #   }


          {url: ActionController::Base.helpers.image_url(label_inside_image(color), host: ENV.fetch("APP_HOST", "http://localhost:3000")), type: "label_inside", options: [{id: "template_type", value: "native"}]}
        ],
      }]
    }

    if version == 'impact'
      front_asset = color == 'white' ? 'logo_black_short.png' : 'logo_white_short.png'
      order_data[:items][0][:files] << {url: ActionController::Base.helpers.image_url(front_asset, host: ENV.fetch("APP_HOST", "http://localhost:3000")), type: 'front'}
    end

    response = printful_service.create_order(order_data)
  end

  attr_reader :request_body, :request_headers

  private

  def label_inside_image(product_color)
    product_color == 'white' ? 'logo_black_short_padded.png' : 'logo_white_short_padded.png'
  end

  def verified?
    hmac_header = request_headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    secret = ENV['SHOPIFY_WEBHOOK_SECRET']

    calculated_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', secret, request_body)
    )

    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
  end

  def order_exists?(response)
    !!Order.find_by(shopify_id: response['id'])
  end

  def create_order(response)
    order = Order.create!(
      shopify_id: response['id'],
      quantity: response['line_items'][0]['quantity'],
      email: response['email'],
      content_url: response['line_items'][0]['properties'][0].values.last.presence,
    )

    file_url = response['line_items'][0]['properties'][1]&.values&.last.presence
    return order unless file_url

    file = URI.open file_url

    order.qr_code_mapping.attach(
      io: file,
      filename: "qrcode-mapping-#{order.id}.#{file_url.split('.').last}",
      content_type: file.content_type
    )

    order
  end
end

# Shopify payload example

# {
#     "id": 6709529444685,
#     "admin_graphql_api_id": "gid://shopify/Order/6709529444685",
#     "app_id": 580111,
#     "browser_ip": "2a01:e34:ec23:800:2c3b:cc73:4f3c:4fc2",
#     "buyer_accepts_marketing": false,
#     "cancel_reason": null,
#     "cancelled_at": null,
#     "cart_token": "Z2NwLWV1cm9wZS13ZXN0MzowMUpXVjNEMks2Vzc0TTg0NERZTVdTMEZXVg",
#     "checkout_id": 44848362225997,
#     "checkout_token": "c1282de50c84a96a75d6a9aab8ea0561",
#     "client_details": {
#         "accept_language": "en",
#         "browser_height": null,
#         "browser_ip": "2a01:e34:ec23:800:2c3b:cc73:4f3c:4fc2",
#         "browser_width": null,
#         "session_hash": null,
#         "user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36"
#     },
#     "closed_at": null,
#     "confirmation_number": "W88EWUJJT",
#     "confirmed": true,
#     "contact_email": "davidmichel77@gmail.com",
#     "created_at": "2025-06-03T16:34:24+02:00",
#     "currency": "EUR",
#     "current_shipping_price_set": {
#         "shop_money": {
#             "amount": "4.18",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "4.18",
#             "currency_code": "EUR"
#         }
#     },
#     "current_subtotal_price": "20.00",
#     "current_subtotal_price_set": {
#         "shop_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         }
#     },
#     "current_total_additional_fees_set": null,
#     "current_total_discounts": "0.00",
#     "current_total_discounts_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "current_total_duties_set": null,
#     "current_total_price": "24.18",
#     "current_total_price_set": {
#         "shop_money": {
#             "amount": "24.18",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "24.18",
#             "currency_code": "EUR"
#         }
#     },
#     "current_total_tax": "0.00",
#     "current_total_tax_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "customer_locale": "en-FR",
#     "device_id": null,
#     "discount_codes": [],
#     "duties_included": false,
#     "email": "davidmichel77@gmail.com",
#     "estimated_taxes": false,
#     "financial_status": "paid",
#     "fulfillment_status": null,
#     "landing_site": null,
#     "landing_site_ref": null,
#     "location_id": null,
#     "merchant_business_entity_id": "MTg5NjczMDcyOTcz",
#     "merchant_of_record_app_id": null,
#     "name": "#1005",
#     "note": null,
#     "note_attributes": [],
#     "number": 5,
#     "order_number": 1005,
#     "order_status_url": "https://kq0fjv-vb.myshopify.com/89673072973/orders/793d13fb0a8299a29aae3a1031a342a1/authenticate?key=980439c5e8b79d975d06621949773b8f",
#     "original_total_additional_fees_set": null,
#     "original_total_duties_set": null,
#     "payment_gateway_names": [
#         "bogus"
#     ],
#     "phone": null,
#     "po_number": null,
#     "presentment_currency": "EUR",
#     "processed_at": "2025-06-03T16:34:21+02:00",
#     "reference": null,
#     "referring_site": null,
#     "source_identifier": null,
#     "source_name": "web",
#     "source_url": null,
#     "subtotal_price": "20.00",
#     "subtotal_price_set": {
#         "shop_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         }
#     },
#     "tags": "",
#     "tax_exempt": false,
#     "tax_lines": [],
#     "taxes_included": true,
#     "test": true,
#     "token": "793d13fb0a8299a29aae3a1031a342a1",
#     "total_cash_rounding_payment_adjustment_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "total_cash_rounding_refund_adjustment_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "total_discounts": "0.00",
#     "total_discounts_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "total_line_items_price": "20.00",
#     "total_line_items_price_set": {
#         "shop_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "20.00",
#             "currency_code": "EUR"
#         }
#     },
#     "total_outstanding": "0.00",
#     "total_price": "24.18",
#     "total_price_set": {
#         "shop_money": {
#             "amount": "24.18",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "24.18",
#             "currency_code": "EUR"
#         }
#     },
#     "total_shipping_price_set": {
#         "shop_money": {
#             "amount": "4.18",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "4.18",
#             "currency_code": "EUR"
#         }
#     },
#     "total_tax": "0.00",
#     "total_tax_set": {
#         "shop_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         },
#         "presentment_money": {
#             "amount": "0.00",
#             "currency_code": "EUR"
#         }
#     },
#     "total_tip_received": "0.00",
#     "total_weight": 380,
#     "updated_at": "2025-06-03T16:34:25+02:00",
#     "user_id": null,
#     "billing_address": {
#         "first_name": "David",
#         "address1": "43 rue des plantes",
#         "phone": null,
#         "city": "Paris",
#         "zip": "75014",
#         "province": null,
#         "country": "France",
#         "last_name": "Michel",
#         "address2": null,
#         "company": null,
#         "latitude": 48.8281695,
#         "longitude": 2.3218881,
#         "name": "David Michel",
#         "country_code": "FR",
#         "province_code": null
#     },
#     "customer": {
#         "id": 8855717216589,
#         "email": "davidmichel77@gmail.com",
#         "created_at": "2025-05-27T20:48:16+02:00",
#         "updated_at": "2025-06-03T16:34:24+02:00",
#         "first_name": "David",
#         "last_name": "Michel",
#         "state": "disabled",
#         "note": null,
#         "verified_email": true,
#         "multipass_identifier": null,
#         "tax_exempt": false,
#         "phone": null,
#         "currency": "EUR",
#         "tax_exemptions": [],
#         "admin_graphql_api_id": "gid://shopify/Customer/8855717216589",
#         "default_address": {
#             "id": 11041882472781,
#             "customer_id": 8855717216589,
#             "first_name": "David",
#             "last_name": "Michel",
#             "company": null,
#             "address1": "43 rue des plantes",
#             "address2": null,
#             "city": "Paris",
#             "province": null,
#             "country": "France",
#             "zip": "75014",
#             "phone": null,
#             "name": "David Michel",
#             "province_code": null,
#             "country_code": "FR",
#             "country_name": "France",
#             "default": true
#         }
#     },
#     "discount_applications": [],
#     "fulfillments": [],
#     "line_items": [
#         {
#             "id": 16735263850829,
#             "admin_graphql_api_id": "gid://shopify/LineItem/16735263850829",
#             "attributed_staffs": [],
#             "current_quantity": 2,
#             "fulfillable_quantity": 2,
#             "fulfillment_service": "printful",
#             "fulfillment_status": null,
#             "gift_card": false,
#             "grams": 190,
#             "name": "Unisex classic tee - M",
#             "price": "10.00",
#             "price_set": {
#                 "shop_money": {
#                     "amount": "10.00",
#                     "currency_code": "EUR"
#                 },
#                 "presentment_money": {
#                     "amount": "10.00",
#                     "currency_code": "EUR"
#                 }
#             },
#             "product_exists": true,
#             "product_id": 10102729146701,
#             "properties": [],
#             "quantity": 2,
#             "requires_shipping": true,
#             "sales_line_item_group_id": null,
#             "sku": "9733786_11577",
#             "taxable": true,
#             "title": "Unisex classic tee",
#             "total_discount": "0.00",
#             "total_discount_set": {
#                 "shop_money": {
#                     "amount": "0.00",
#                     "currency_code": "EUR"
#                 },
#                 "presentment_money": {
#                     "amount": "0.00",
#                     "currency_code": "EUR"
#                 }
#             },
#             "variant_id": 51734523248973,
#             "variant_inventory_management": "shopify",
#             "variant_title": "M",
#             "vendor": "QR shirts",
#             "tax_lines": [],
#             "duties": [],
#             "discount_allocations": []
#         }
#     ],
#     "payment_terms": null,
#     "refunds": [],
#     "shipping_address": {
#         "first_name": "David",
#         "address1": "43 rue des plantes",
#         "phone": null,
#         "city": "Paris",
#         "zip": "75014",
#         "province": null,
#         "country": "France",
#         "last_name": "Michel",
#         "address2": null,
#         "company": null,
#         "latitude": 48.8281695,
#         "longitude": 2.3218881,
#         "name": "David Michel",
#         "country_code": "FR",
#         "province_code": null
#     },
#     "shipping_lines": [
#         {
#             "id": 5587049644365,
#             "carrier_identifier": null,
#             "code": "EU Flat Rate",
#             "current_discounted_price_set": {
#                 "shop_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 },
#                 "presentment_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 }
#             },
#             "discounted_price": "4.18",
#             "discounted_price_set": {
#                 "shop_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 },
#                 "presentment_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 }
#             },
#             "is_removed": false,
#             "phone": null,
#             "price": "4.18",
#             "price_set": {
#                 "shop_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 },
#                 "presentment_money": {
#                     "amount": "4.18",
#                     "currency_code": "EUR"
#                 }
#             },
#             "requested_fulfillment_service_id": null,
#             "source": "shopify",
#             "title": "EU Flat Rate",
#             "tax_lines": [],
#             "discount_allocations": []
#         }
#     ],
#     "returns": []
# }
