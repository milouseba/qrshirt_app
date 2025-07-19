class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def shopify_order
    puts response.body
  end

  def new
    @order = Order.new(email: 'milouseba@gmail.com', content_url: 'https://upload.wikimedia.org/wikipedia/commons/6/6a/PNG_Test.png')
  end

  def show
    @order = Order.find(params[:id])
  end

  def create
    @order = Order.new(order_params)

    if @order.save
      qrcode_url = GenerateQrCodeService.call(@order, @order.content_url)
  
      # 3. Uploader vers Printful et créer la commande
      printful_service = PrintfulService.new
      order_data = {
        external_id: @order.id,
        recipient: {
          name: 'Sebastien Milou',
          email: @order.email,
          address1: '8 rue du delta',
          city: 'Paris',
          zip: '75009',
          country: 'FR',
        },
        items: [{
          variant_id: params[:order][:variant_id], # Remplace par le bon variant_id
          quantity: @order.quantity,
          files: [{ url: qrcode_url }],
          options: [{ id: "placement", value: "front" }]
        }]
      }
      response = printful_service.create_order(order_data)
      Rails.logger.info("Printful API response: #{response.inspect}")

      if response['error']
        flash[:alert] = "Erreur : #{response['error']}"
        render :new
      else
        redirect_to order_path(@order), notice: 'Commande envoyée à Printful !'
      end
    else
      render :new
    end
  end

  def confirm
    @order = Order.find(params[:id])
    printful_service = PrintfulService.new
    response = printful_service.confirm_order(@order.id)

    if response['error']
      flash[:alert] = "Erreur lors de la confirmation : #{response['error']}"
    else
      flash[:notice] = "Commande confirmée avec succès !"
    end

    redirect_to order_path(@order)
  end

  def payment_success
    @order = Order.find(params[:id])
    @order.update!(paid: true, paypal_order_id: params[:paypal_order_id])
  
    printful_service = PrintfulService.new
    response = printful_service.confirm_order(@order.id)
  
    if response['error']
      flash[:alert] = "Erreur lors de la confirmation : #{response['error']}"
    else
      flash[:notice] = "Commande confirmée avec succès !"
    end

    redirect_to order_path(@order)
  end

  private

  def order_params
    params.require(:order).permit(:email, :content_type, :content_url, :quantity)
  end
end


# payload example for orders
# {
#   "external_id": 1907001,
#   "recipient": {
#     "name": "Sebastien Milou",
#     "email": "milouseba@gmail.com",
#     "address1": "8 rue du delta",
#     "city": "Paris",
#     "zip": "75009",
#     "country": "FR"
#   },
#   "items": 
#     [{
#       "variant_id": 11576,
#       "sync_variant_id": 4893393109,
#       "quantity": 1,
#       "files": [
#         { "url": "https://media.hovercode.com/media/codes/877cba10-b284-4fc1-88d4-250f1e9edd1e_P5i6AWz.png",
#           "placement": "back",
#           "position": {
#             "area_width": 1800,
#             "area_height": 2400,
#             "width": 500,
#             "height": 500,
#             "top": 300,
#             "left": 0,
#             "limit_to_print_area": true
#           }
#         }
#       ],
#       "options": [{ "id": "placement", "value": "back" }]
#     }]
# }
