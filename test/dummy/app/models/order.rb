class Order < ApplicationRecord
  has_many :order_items
  has_many :products, through: :order_items
  belongs_to :user, optional: true

  enum state: %w[ready confirmed sent received suspend]
end
