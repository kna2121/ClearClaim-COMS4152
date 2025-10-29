require "rails_helper"

RSpec.describe "ClaimsController", type: :request do
  describe "POST /claims/suggest_corrections" do
    let!(:denial) do
      create(
        :denial_reason,
        code: "125",
        group_code: "CO",
        reason_codes: ["29"],
        remark_code: "N211",
        description: "Denied. Bill was received after 90 days."
      )
    end

    it "returns suggestions when tuples are provided in denial_codes" do
      post "/claims/suggest_corrections",
           params: {
             denial_codes: [
               ["CO29", "N211"]
             ]
           }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload["suggestions"]).to include(
        a_hash_including(
          "code" => "125",
          "group_code" => "CO",
          "reason_code" => "29",
          "remark_code" => "N211"
        )
      )
    end
  end

  # describe "POST /claims/generate_appeal" do
  #   let!(:denial) do
  #     create(
  #       :denial_reason,
  #       code: "157",
  #       group_code: "PR",
  #       reason_codes: ["3"],
  #       remark_code: nil,
  #       description: "Not responsible for replacement of contacts."
  #     )
  #   end

  #   it "generates an appeal using the denial tuples provided in denials param" do
  #     post "/claims/generate_appeal",
  #          params: {
  #            claim: {
  #              claim_number: "12345",
  #              patient_name: "Jane Doe",
  #              payer_name: "Clear Health",
  #              service_period: "Jan 1-5 2024",
  #              submitter_name: "ClearClaim Assistant"
  #            },
  #            denials: [
  #              ["PR3", nil]
  #            ]
  #          }.to_json,
  #          headers: { "CONTENT_TYPE" => "application/json" }

  #     expect(response).to have_http_status(:ok)
  #     payload = JSON.parse(response.body)
  #     expect(payload).to include("body")
  #   end
  # end
end
