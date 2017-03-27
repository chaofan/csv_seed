class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :code, index: true
      t.text :desc
      t.boolean :onself, default: false
      t.decimal :price, precision: 8, scale: 2, default: 0.0
      t.integer :sort_no, default: 0

      t.timestamps
    end
  end
end
