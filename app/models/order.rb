class Order < ApplicationRecord
  has_one_attached :qr_code

  validates :email, presence: true
  validates :content_type, inclusion: { in: ['link', 'image', 'video'] }
  validates :content_url, presence: true
end
