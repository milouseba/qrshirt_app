Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resources :orders, only: [:new, :create, :show] do
    member do
      post :confirm
    end
    collection do
      post :shopify_order
      post :update_qr
    end
  end

  root to: "orders#new"

  post 'orders/:id/payment_success', to: 'orders#payment_success', as: :payment_success_order

  post 'webhooks/shopify_order_paid', to: 'webhooks#shopify_order_paid'
  post 'webhooks/printful_order_updated', to: 'webhooks#printful_order_updated'
end
