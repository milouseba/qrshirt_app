class Order < ApplicationRecord
  has_one_attached :qr_code
end
