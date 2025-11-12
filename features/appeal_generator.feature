@no_db
Feature: Appeals::AppealGenerator service
  As a developer
  I want AppealGenerator to render letters in test mode and handle errors
  So that we have reliable generation without external dependencies

  Scenario: Render template in test environment
    Given a sample claim with claim number "CC-0001" and patient "Jane Doe"
    And denial reasons list:
      | code  | reason                     | suggested_correction          |
      | CO197 | Missing pre-authorization  | Provide prior auth documents. |
    When I generate an appeal via the service
    Then the appeal letter should include "Jane Doe"
    And the appeal letter should include "CC-0001"

  Scenario: Rescue when template rendering fails
    Given a sample claim with claim number "CC-0002" and patient "John Roe"
    And denial reasons list:
      | code | reason |
      | 001  | Test   |
    And ERB rendering will raise "boom"
    When I generate an appeal via the service
    Then I should receive an appeal generation error containing "LLM generation failed: boom"

  Scenario: Force remote LLM path with stubbed response
    Given a sample claim with claim number "CC-0003" and patient "Chris Smith"
    And denial reasons list:
      | code | reason |
      | 002  | Test   |
    And I force generator to use remote LLM with mocked reply "Mock LLM letter"
    When I generate an appeal via the service
    Then the appeal letter should include "Mock LLM letter"

