Rails.application.config.middleware.use OmniAuth::Builder do
  provider :oauth2,
    ENV['PRINTFUL_CLIENT_ID'],
    ENV['PRINTFUL_CLIENT_SECRET'],
    client_options: {
      site: 'https://www.printful.com',
      authorize_url: 'https://www.printful.com/oauth/authorize',
      token_url: 'https://www.printful.com/oauth/token'
    }
end