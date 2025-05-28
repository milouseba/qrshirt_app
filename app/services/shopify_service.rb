class ShopifyService
  def self.call(payload)
    new(payload).call
  end

  def initialize(payload)
    @payload = payload
  end

  def call
    return unless valid?

  end

  private

  def method_name

  end
end
