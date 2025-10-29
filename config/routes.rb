# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#index"

  resources :claims, only: [] do
    collection do
      post :analyze
      post :suggest_corrections
      post :generate_appeal
    end
  end
end
