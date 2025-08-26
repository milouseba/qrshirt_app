class Order < ApplicationRecord
  has_one_attached :qr_code
  has_one_attached :qr_code_mapping

  validates :email, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :shopify_id, presence: true, uniqueness: true
end
