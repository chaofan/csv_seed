class CreateOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :orders do |t|
      t.integer :user_id, index: true
      t.decimal :total, precision: 8, scale: 2, default: 0.0
      t.string :receiver_mobile
      t.string :receiver_address
      t.integer :state, index: true, default: 0
      t.integer :order_items_count, default: 0

      t.timestamps
    end
  end
end
