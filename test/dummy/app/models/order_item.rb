class OrderItem < ApplicationRecord
  belongs_to :order, counter_cache: true
  belongs_to :product
end
