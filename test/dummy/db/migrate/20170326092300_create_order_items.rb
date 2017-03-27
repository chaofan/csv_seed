class CreateOrderItems < ActiveRecord::Migration[5.0]
  def change
    create_table :order_items do |t|
      t.integer :order_id, index: true
      t.integer :product_id, index: true
      t.integer :items_count
      t.decimal :item_price, precision: 8, scale: 2, default: 0.0

      t.timestamps
    end
  end
end
