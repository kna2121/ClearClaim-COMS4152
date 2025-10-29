# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#index"

  resources :claims, only: [] do
    collection do
      post :analyze
      post :suggest_corrections
      post :generate_appeal
      post "/appeals", to: "appeals#create"
    end
  end
end
