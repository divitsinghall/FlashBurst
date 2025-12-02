class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.integer :product_variant_id
      t.string :status

      t.timestamps
    end
  end
end
