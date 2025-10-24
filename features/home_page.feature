Feature: Visit the home page
  As a healthcare administrator
  I want to see the AI Appeal Assistant welcome page
  So that I know the service is ready for configuration

  Scenario: Viewing the default landing screen
    Given I visit the home page
    Then I should see "AI Appeal Assistant"
