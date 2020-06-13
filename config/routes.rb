Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "homepages#index"
  
  get "/auth/github", as: "github_login"
  get "/auth/:provider/callback", to: "merchants#create", as: "oauth_callback"
  post "/logout", to: "merchants#logout", as: "logout"
  
  get "orders/lookup", to: "orders#lookup", as: "order_lookup"
  get "orders/cart", to: "orders#cart", as: "order_cart"
  patch "products/cart", to: "products#cart", as: "product_cart"
  patch "remove/:id", to: "products#remove_from_cart", as: "product_remove_cart"
  patch "cart/update/:id", to: "products#update_quant", as: "update_quant"
  delete "orders/:id/cancel", to: "orders#cancel", as: "cancel_order"
  delete "order_items/:id/cancel", to: "order_items#cancel", as: "cancel_item"
  patch "products/:id/active", to: "products#toggle_active", as: "toggle_active"
  patch "order_items/:id/ship", to: "order_items#ship", as: "ship_item"

  resources :products, except: [:new] do
    resources :reviews, only: [:new, :create]
  end

  resources :merchants, only: [:index, :show] do
    resources :products, only: [:index, :new, :create]
    resources :order_items, only: [:index]
  end

  resources :orders, only: [:show, :new, :create]

  resources :order_items, only: [:create, :edit, :update, :destroy]

  resources :categories, only: [:new, :create, :index] do
    resources :products, only: [:index]
  end
end
