require "rails_helper"
require "zip"
require "stringio"
require "rexml/document"

RSpec.describe "Appeals", type: :request do
  it "generates an appeal letter" do
    post "/claims/generate_appeal", params: {
      claim: {
        claim_number: "A123",
        patient_name: "John Doe",
        payer_name: "Aetna",
        service_period: "2025-01-10"
      },
      denial_codes: [{ code: "CO197", reason: "Missing pre-authorization" }]
    }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["appeal_letter"]).to include("Aetna")
  end

  describe "GET /appeal_letter downloads" do
    let(:letter_body) do
      <<~TEXT
        [Your Name]
        [Your Title]
        [Your Organization]

        Dear Claims Review Department,

        Please reach out if clarification is required.
      TEXT
    end

    it "streams the appeal letter as plain text" do
      get appeal_letter_path(format: :text, content: letter_body)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.body).to include("Dear Claims Review Department")
    end

    it "streams the appeal letter as docx with the body content" do
      get appeal_letter_path(format: :docx, content: letter_body)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      extracted_text = extract_docx_text(response.body)
      expect(extracted_text).to include("Please reach out if clarification is required.")
      expect(extracted_text).not_to include("Attachments")
    end
  end

  def extract_docx_text(binary)
    text = +""
    Zip::File.open_buffer(StringIO.new(binary)) do |zip|
      xml = zip.read("word/document.xml")
      doc = REXML::Document.new(xml)
      doc.elements.each("//w:t") { |node| text << node.text.to_s }
    end
    text
  end
end
