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
  get "/appeal_letter", to: "appeals#show"

  # Allow headless browser tests to request favicon without raising errors.
  get "/favicon.ico", to: proc { [204, {}, []] }
end
