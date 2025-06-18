class AddQrCodeIdToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :qr_code_id, :string
  end
end
