class RemoveColumnsFromOrders < ActiveRecord::Migration[7.1]
  def change
    remove_column :orders, :paid
    remove_column :orders, :paypal_order_id
    remove_column :orders, :size
  end
end
