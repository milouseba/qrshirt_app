class CreateTshirts < ActiveRecord::Migration[7.1]
  def change
    create_table :tshirts do |t|
      t.string :size, null: false
      t.string :color, null: false
      t.string :printful_order_id
      t.string :printful_order_status

      t.timestamps
    end
  end
end 