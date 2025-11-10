# frozen_string_literal: true

Before('@upload_flow') do
  sample_claim = {
    claim_number: "202303EF123",
    patient_name: "Dave Doe",
    payer_name: "Acme Health",
    service_period: "11/27/2024",
    submitter_name: "ClearClaim Clinic"
  }

  analyzer_double = instance_double(Claims::DocumentAnalyzer, call: sample_claim)
  allow(Claims::DocumentAnalyzer).to receive(:new).and_return(analyzer_double)

  denial_suggestions = [{
    code: "CO197",
    description: "Charge exceeds fee schedule",
    suggested_correction: "Review payer contract and include supporting documentation."
  }]
  suggester_double = instance_double(Claims::CorrectionSuggester, call: denial_suggestions)
  allow(Claims::CorrectionSuggester).to receive(:new).and_return(suggester_double)

  appeal_letter_text = <<~LETTER
    [Your Name]
    [Your Title]
    [Your Organization]

    Dear Claims Review Department,

    Please accept this appeal regarding claim CC-202303EF123.
  LETTER
  generator_double = instance_double(Appeals::AppealGenerator, call: { appeal_letter: appeal_letter_text })
  allow(Appeals::AppealGenerator).to receive(:new).and_return(generator_double)
end
