
Feature: Uploading a file
    As a user
    I want to upload a file
    So that it can be analyzed

    Scenario: Uploading a PDF successfully
        Given I visit the home page
        When I upload "Dave_Doe_EOB_input.pdf"
        Then the "Analyze Document" button should become enabled
        And I press "Analyze Document"
        And I should see "Claim Analysis Results"

