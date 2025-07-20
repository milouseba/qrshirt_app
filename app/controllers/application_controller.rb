class ApplicationController < ActionController::Base
  def default_url_options
    { host: ENV["APP_HOST"] }
  end
end
