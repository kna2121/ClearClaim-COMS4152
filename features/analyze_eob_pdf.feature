# Cucumber Feature File
# 
# Cucumber uses Gherkin syntax:
# - Feature: High-level description of functionality
# - Scenario: Specific test case
# - Given/When/Then: Test steps (Arrange/Act/Assert pattern)
#
# This file defines user stories for PDF analysis functionality

Feature: Analyze medical denial PDFs
  As a healthcare claims specialist
  I want to upload and analyze EOB (Explanation of Benefits) PDFs
  So that I can extract patient demographics and denial codes for appeal preparation

  Background:
    Given the system is configured to analyze EOB documents

  # Scenario 1: Extract Demographics
  # This tests that we can extract all required demographic fields
  Scenario: Extract patient demographics from EOB PDF
    Given I have an EOB PDF with the following patient information:
      | Field      | Value        |
      | Patient    | DOE, DAVE    |
      | DOB        | 01/29/1964   |
      | Insured    | DOE, DAVE    |
      | Member ID  | ABC123EFG    |
      | ICN        | 202303EF123  |
    When I upload the PDF for analysis
    Then the system should extract the following demographics:
      | Field         | Value        |
      | patient_name  | DOE, DAVE    |
      | dob           | 01/29/1964   |
      | insured       | DOE, DAVE    |
      | member_id     | ABC123EFG    |
      | icn           | 202303EF123  |

  # Scenario 2: Extract Billing Line Items
  # This tests extraction of service dates, procedures, and codes
  Scenario: Extract billing line items with denial codes
    Given I have an EOB PDF with the following line items:
      | Service Date | Procedure | Billed | Remit Code | Remark Code |
      | 11/27/2024   | 99215     | 940.00 | CO29       | N211        |
      | 11/27/2024   | G2211     | 50.00  | CO29       | N211        |
      | 11/27/2024   | 80307     | 250.00 | PR3        |             |
    When I upload the PDF for analysis
    Then the system should extract 3 line items
    And line item 1 should have:
      | Field          | Value      |
      | service_date   | 11/27/2024 |
      | procedure_code | 99215      |
      | billed         | 940.00     |
    And line item 1 should have remit code "CO29"
    And line item 1 should have remark code "N211"

  # Scenario 3: Separate Remit vs Remark Codes
  # This tests that we correctly distinguish between code types
  Scenario: Distinguish between remit and remark codes
    Given I have an EOB PDF with denial codes "CO29", "PR3", "N211", and "M86"
    When I upload the PDF for analysis
    Then the remit codes should include:
      | Code |
      | CO29 |
      | PR3  |
    And the remark codes should include:
      | Code |
      | N211 |
      | M86  |

  # Scenario 4: Handle Multiple Pages
  # Real EOBs may span multiple pages
  Scenario: Extract data from multi-page EOB
    Given I have a 3-page EOB PDF with line items on each page
    When I upload the PDF for analysis
    Then the system should extract line items from all pages
    And all line items should have valid service dates

  # Scenario 5: Error Handling
  # Test graceful handling of bad input
  Scenario: Handle malformed PDF gracefully
    Given I have a corrupted PDF file
    When I attempt to upload it for analysis
    Then I should receive an error message "Unable to read PDF"
    And the error should be user-friendly

  # Scenario 6: Missing Fields
  # EOBs may have incomplete data
  Scenario: Handle EOB with missing demographic fields
    Given I have an EOB PDF with patient name but no DOB
    When I upload the PDF for analysis
    Then the patient_name should be extracted
    And the dob should be nil
    And the system should not fail

  # Scenario 7: API Integration
  # Test the HTTP endpoint
  Scenario: Analyze PDF via API endpoint
    Given I have a valid EOB PDF file
    When I POST the file to "/claims/analyze"
    Then the response status should be 200
    And the response should contain "demographics"
    And the response should contain "line_items"
    And the response should contain "denial_codes"

  # Scenario 8: Legacy Compatibility
  # Ensure we don't break existing integrations
  Scenario: Maintain backward compatibility with legacy format
    Given I have an EOB PDF
    When I upload the PDF for analysis
    Then the response should include legacy fields:
      | Field         |
      | patient_name  |
      | claim_number  |
      | denial_codes  |
    And the "denial_codes" field should be a flat array
    And the "claim_number" should equal the ICN value