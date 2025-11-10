@javascript @upload_flow
Feature: Uploading a file
    As a user
    I want to upload a file
    So that it can be analyzed and generate an appeal letter

    Scenario: Uploading a PDF successfully and generating an appeal letter
        Given I visit the home page
        When I upload "Dave_Doe_EOB_input.pdf"
        Then the "Analyze Document" button should become enabled
        And I press "Analyze Document"
        And I should see "Claim Analysis Results"
        And I press "Generate Appeal Letter"
        Then I should see "Generated Appeal Letter"
        And I should see "Dear Claims Review Department"
