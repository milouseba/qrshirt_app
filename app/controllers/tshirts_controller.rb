class TshirtsController < ApplicationController
  def new
    @tshirt = Tshirt.new(size: 'M', color: 'White')
  end

  def create
    Rails.logger.info "=== DÉBUT DE LA CRÉATION DU T-SHIRT ==="
    Rails.logger.info "Paramètres reçus: #{params.inspect}"
    
    @tshirt = Tshirt.new(tshirt_params)
    
    if @tshirt.save
      Rails.logger.info "T-shirt sauvegardé avec succès (ID: #{@tshirt.id})"
      
      # Générer le QR code
      begin
        Rails.logger.info "Génération du QR code pour l'URL: #{params[:qr_code_url]}"
        @tshirt.generate_qr_code(params[:qr_code_url])
        Rails.logger.info "QR code généré avec succès"
      rescue => e
        Rails.logger.error "ERREUR QR CODE: #{e.message}"
        @tshirt.destroy
        flash[:alert] = "Erreur lors de la génération du QR code: #{e.message}"
        redirect_to new_tshirt_path and return
      end
      
      # Créer la commande Printful
      begin
        Rails.logger.info "Initialisation du service Printful"
        printful_service = PrintfulService.new(ENV['PRINTFUL_API_KEY'])
        
        Rails.logger.info "Upload du QR code vers Printful"
        file_id = printful_service.upload_qr_code(@tshirt)
        Rails.logger.info "QR code uploadé avec succès (file_id: #{file_id})"

        order_data = {
          recipient: {
            name: "Customer Name",
            address1: "123 Main St",
            city: "City",
            state_code: "State",
            country_code: "FR",
            zip: "12345"
          },
          items: [{
            variant_id: get_variant_id(@tshirt.color, @tshirt.size),
            quantity: 1,
            files: [{ id: file_id }],
            options: [{ id: "placement", value: "front" }]
          }]
        }

        Rails.logger.info "Envoi de la commande Printful: #{order_data.inspect}"
        response = printful_service.create_order(order_data)
        Rails.logger.info "Réponse Printful reçue: #{response.inspect}"

        if response['error']
          Rails.logger.error "ERREUR PRINTFUL: #{response['error']}"
          @tshirt.destroy
          flash[:alert] = "Erreur lors de la création de la commande Printful: #{response['error']}"
          redirect_to new_tshirt_path and return
        else
          Rails.logger.info "Commande Printful créée avec succès"
          @tshirt.update(
            printful_order_id: response['result']['id'],
            printful_order_status: response['result']['status']
          )
          flash[:notice] = 'T-shirt créé avec succès et commande Printful initiée!'
          redirect_to tshirt_path(@tshirt) and return
        end
      rescue => e
        Rails.logger.error "ERREUR PRINTFUL: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        @tshirt.destroy
        flash[:alert] = "Erreur lors de la communication avec Printful : #{e.message}"
        redirect_to new_tshirt_path and return
      end
    else
      Rails.logger.error "ERREURS DE VALIDATION: #{@tshirt.errors.full_messages}"
      flash.now[:alert] = "Erreurs de validation: #{@tshirt.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tshirt = Tshirt.find(params[:id])
  end

  private

  def tshirt_params
    params.require(:tshirt).permit(:size, :color)
  end

  def get_variant_id(color, size)
    variants = {
      'White' => { 'S' => 4011, 'M' => 4012, 'L' => 4013, 'XL' => 4014, 'XXL' => 4015 },
      'Black' => { 'S' => 4016, 'M' => 4017, 'L' => 4018, 'XL' => 4019, 'XXL' => 4020 },
      'Navy' => { 'S' => 4021, 'M' => 4022, 'L' => 4023, 'XL' => 4024, 'XXL' => 4025 },
      'Blue' => { 'S' => 4026, 'M' => 4027, 'L' => 4028, 'XL' => 4029, 'XXL' => 4030 },
      'Red' => { 'S' => 4031, 'M' => 4032, 'L' => 4033, 'XL' => 4034, 'XXL' => 4035 }
    }
    variants[color][size]
  end
end 