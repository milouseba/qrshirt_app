class AddFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :shopify_id, :string
    add_column :orders, :size, :string
  end
end
