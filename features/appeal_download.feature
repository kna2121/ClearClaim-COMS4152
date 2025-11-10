Feature: Downloading generated appeal letters
  As a healthcare claims specialist preparing payer appeals
  I want to export generated letters in multiple formats
  So that I can attach them to emails or upload them to payer portals

  Background:
    Given I have a generated appeal letter payload

  Scenario: Export the appeal letter as plain text for quick emailing
    When I request the appeal letter download as "text"
    Then the response should be a file download named "appeal_letter"
    And the download should be plain text including "Dear Claims Review Department"

  Scenario: Export the appeal letter as DOCX for payer portal submission
    When I request the appeal letter download as "docx"
    Then the response should be a file download named "appeal_letter"
    And the download should be a docx file containing "Please contact me directly"
