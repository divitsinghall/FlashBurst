class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants do |t|
      t.string :name
      t.integer :inventory_count

      t.timestamps
    end
  end
end
