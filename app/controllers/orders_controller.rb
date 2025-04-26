class OrdersController < ApplicationController
  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)
    
    if @order.save
      # Génération du QR Code
      qr_code_service = GenerateQrCodeService.new(@order.content_url)
      qr_code_png = qr_code_service.call

      # Sauvegarde du QR code dans ActiveStorage
      @order.qr_code.attach(io: StringIO.new(qr_code_png), filename: "qr_code.png", content_type: "image/png")

      # Créer la commande Printful
      printful_service = PrintfulService.new
      order_data = {
        recipient: { email: @order.email },
        items: [{
          variant_id: 1, # Assurez-vous d'utiliser un ID de produit Printful valide
          quantity: 1,
          files: [{ url: rails_blob_url(@order.qr_code, only_path: true) }]
        }]
      }
      response = printful_service.create_order(order_data)

      # Redirection ou affichage de la confirmation
      redirect_to order_path(@order), notice: 'Commande envoyée à Printful !'
    else
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit(:email, :content_type, :content_url)
  end
end