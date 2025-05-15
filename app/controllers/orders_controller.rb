class OrdersController < ApplicationController
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
