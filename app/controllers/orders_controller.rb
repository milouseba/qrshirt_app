class OrdersController < ApplicationController
  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)
  
    if @order.save
      # 1. Générer le QR code
      qr_code_service = GenerateQrCodeService.new(@order.content_url)
      qr_code_png = qr_code_service.call
  
      # 2. Attacher à ActiveStorage
      @order.qr_code.attach(
        io: StringIO.new(qr_code_png),
        filename: "qr_code.png",
        content_type: "image/png"
      )
  
      # 3. Uploader vers Printful et créer la commande
      printful_service = PrintfulService.new
      begin
        file_id = printful_service.upload_qr_code(@order)
  
        order_data = {
          recipient: { email: @order.email },
          items: [{
            variant_id: 4012, # Remplace par le bon variant_id
            quantity: 1,
            files: [{ id: file_id }],
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
      rescue => e
        flash[:alert] = "Erreur lors de la communication avec Printful : #{e.message}"
        render :new
      end
    else
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit(:email, :content_type, :content_url)
  end
end