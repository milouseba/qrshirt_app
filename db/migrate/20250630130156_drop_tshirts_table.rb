class DropTshirtsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :tshirts
  end
end
