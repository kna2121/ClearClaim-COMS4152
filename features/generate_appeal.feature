

Feature: Generate appeal letter
    As a healthcare claims processor
    I want to generate a formal claim appeal letter
    So that I can submit it to the payer to contest a denial


Scenario: Generating an appeal letter
    Given a denial claim with claim number "12345" and name "Jane Doe"
    And the denial reasons are:
      | code   | reason                    |
      | CO197  | Missing pre-authorization |
    When I request to generate an appeal letter
    Then I should receive a successful response
    And the response should include the patient name "Jane Doe".


