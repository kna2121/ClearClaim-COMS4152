require "rails_helper"

RSpec.describe "ClaimsController", type: :request do
  describe "POST /claims/analyze" do
    it "returns 200 and JSON with claim fields for a valid PDF" do
      pdf_path = Rails.root.join("spec", "fixtures", "files", "api_sample.pdf")
      FileUtils.mkdir_p(File.dirname(pdf_path))
      require 'prawn'
      Prawn::Document.generate(pdf_path) do
        text "Patient: DOE, DAVE"
        text "ICN: 202303EF123"
        text "11/27/2024 | 99215 | $940.00 | CO29 | N211"
      end

      file = Rack::Test::UploadedFile.new(pdf_path, 'application/pdf')
      post "/claims/analyze", params: { file: file }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["claim"]).to include("demographics", "line_items", "denial_codes")
    ensure
      FileUtils.rm_f(pdf_path)
    end

    it "returns 422 with error message for corrupted PDF" do
      pdf_path = Rails.root.join("spec", "fixtures", "files", "bad.pdf")
      FileUtils.mkdir_p(File.dirname(pdf_path))
      File.write(pdf_path, "not a pdf")

      file = Rack::Test::UploadedFile.new(pdf_path, 'application/pdf')
      post "/claims/analyze", params: { file: file }

      expect(response).to have_http_status(:unprocessable_entity)
      data = JSON.parse(response.body)
      expect(data["error"]).to match(/Unable to read PDF/)
    ensure
      FileUtils.rm_f(pdf_path)
    end
  end
end

