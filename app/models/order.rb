class Order < ApplicationRecord
  has_one_attached :qr_code

  validates :email, presence: true
  validates :content_type, inclusion: { in: ['link', 'image', 'video'] }
  validates :content_url, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :size, presence: true
  validates :shopify_id, presence: true, uniqueness: true
end
