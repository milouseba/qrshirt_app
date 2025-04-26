class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :email
      t.string :content_type
      t.string :content_url

      t.timestamps
    end
  end
end
