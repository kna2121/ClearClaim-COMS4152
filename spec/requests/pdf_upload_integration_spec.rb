# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'PDF Upload Integration', type: :request do
  let(:valid_pdf_path) { Rails.root.join('spec', 'fixtures', 'files', 'integration_test.pdf') }
  
  before do
    FileUtils.mkdir_p(File.dirname(valid_pdf_path))
    require 'prawn'
    Prawn::Document.generate(valid_pdf_path) do
      text "Patient: JONES, MARY"
      text "ICN: 202310CD789"
      text "Payer: Aetna"
      text "Service Period: 01/15/2024 - 01/15/2024"
    end
  end
  
  after do
    FileUtils.rm_f(valid_pdf_path)
  end
  
  describe 'POST /claims/analyze from upload form' do
    it 'accepts PDF upload and returns analysis results' do
      file = Rack::Test::UploadedFile.new(valid_pdf_path, 'application/pdf')
      
      post '/claims/analyze', params: { file: file }
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      
      json = JSON.parse(response.body)
      expect(json).to have_key('claim')
      expect(json['claim']).to be_a(Hash)
    end
    
    it 'returns error for missing file' do
      post '/claims/analyze', params: {}
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json).to have_key('error')
    end
    
    it 'returns error for non-PDF file' do
      txt_path = Rails.root.join('spec', 'fixtures', 'files', 'test.txt')
      FileUtils.mkdir_p(File.dirname(txt_path))
      File.write(txt_path, 'This is not a PDF')
      
      file = Rack::Test::UploadedFile.new(txt_path, 'text/plain')
      post '/claims/analyze', params: { file: file }
      
      expect(response).to have_http_status(:unprocessable_entity)
      
      FileUtils.rm_f(txt_path)
    end
    
    it 'handles large file gracefully' do
      # Simulate a file that's too large (this would be caught by frontend)
      allow_any_instance_of(ActionDispatch::Http::UploadedFile)
        .to receive(:size).and_return(11.megabytes)
      
      file = Rack::Test::UploadedFile.new(valid_pdf_path, 'application/pdf')
      post '/claims/analyze', params: { file: file }
      
      # Backend should still process it unless you add size validation
      expect(response).to have_http_status(:ok).or have_http_status(:unprocessable_entity)
    end
  end
end