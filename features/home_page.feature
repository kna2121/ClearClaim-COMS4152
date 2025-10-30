Feature: Visit the home page
  As a healthcare administrator
  I want to see the ClearClaim welcome page
  So that I know the service is ready for configuration

  Scenario: Viewing the default landing screen
    Given I visit the home page
    Then I should see "ClearClaim"
