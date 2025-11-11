Feature: Complete PDF Analysis and Appeal Generation
  As a healthcare claims specialist
  I want to upload an EOB PDF and generate appeals
  So that I can efficiently process claim denials

  Scenario: Extract all required fields from EOB PDF
    Given I have an EOB PDF with complete information:
      | Field           | Value                    |
      | Payer           | ABC INSURANCE COMPANY    |
      | Patient         | DOE, DAVE               |
      | ICN             | 202303EF123             |
      | Provider        | ClearClaim Assistant|
      | Service Date    | 11/27/2024              |
      | Remit Code      | CO29                    |
      | Remark Code     | N211                    |
    When I upload the PDF for analysis
    Then the analysis should include:
      | Field           | Value                    |
      | payer_name      | ABC INSURANCE COMPANY    |
      | patient_name    | DOE, DAVE               |
      | claim_number    | 202303EF123             |
      | submitter_name  | ClearClaim Assistant|
      | service_period  | 11/27/2024              |
    And the line items should contain remit code "CO29"
    And the line items should contain remark code "N211"

  Scenario: Generate appeal with extracted data
    Given I have analyzed an EOB PDF
    When I request to generate an appeal
    Then the appeal should reference the correct claim number
    And the appeal should include the patient name
    And the appeal should address the insurance company