@javascript

Feature: Uploading a file
    As a user
    I want to upload a file
    So that it can be analyzed

    Scenario: Uploading a PDF successfully
        Given I visit the home page
        When I click the upload area
        And I upload "Dave_Doe_EOB_input.pdf"
        Then I should see the file name "Dave_Doe_EOB_input.pdf"
        And I press "Analyze Document"
        And I should see "Claim Analysis Results"

