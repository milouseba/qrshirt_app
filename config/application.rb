require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module QrshirtApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    ShopifyAPI::Context.setup(
      api_key: ENV['SHOPIFY_API_KEY'],
      api_secret_key: ENV['SHOPIFY_API_SECRET_KEY'],
      host: "https://kq0fjv-vb.myshopify.com",
      scope: "read_orders, write_orders, write_order_edits, read_order_edits",
      is_embedded: false,
      api_version: "2025-04", # The version of the API you would like to use
      is_private: false, # Set to true if you have an existing private app
    )
  end
end
