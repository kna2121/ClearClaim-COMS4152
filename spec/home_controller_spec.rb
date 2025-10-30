# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
    
    it 'responds with HTML' do
      get :index
      expect(response.content_type).to include('text/html')
    end
  end
end