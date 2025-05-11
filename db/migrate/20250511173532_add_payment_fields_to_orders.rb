class AddPaymentFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :paid, :boolean
    add_column :orders, :paypal_order_id, :string
  end
end
