@no_db
Feature: DocumentAnalyzer PDF detection
  As a developer
  I want DocumentAnalyzer to only accept PDFs
  So that non-PDF inputs are rejected and PDF detection is robust

  Scenario: Rejecting a non-PDF input
    When I analyze a non-PDF IO object
    Then I should receive a DocumentAnalyzer error "Only PDF files are supported"

  Scenario: Error when file is missing
    When I call DocumentAnalyzer with no file
    Then I should receive a DocumentAnalyzer error "file is required"

  Scenario: Accepting by content type
    Given I have a valid PDF in memory
    When I analyze with content_type set to application/pdf
    Then the analyzer should route to PdfAnalyzer

  Scenario: Accepting by original filename
    Given I have a valid PDF in memory
    When I analyze with original_filename ending in .pdf
    Then the analyzer should route to PdfAnalyzer

  Scenario: Accepting by local path
    Given I have a valid PDF file on disk
    When I analyze it via File path
    Then the analyzer should route to PdfAnalyzer

  Scenario: Accepting by header sniff
    Given I have a valid PDF in memory
    When I analyze a stream that starts with the PDF header
    Then the analyzer should route to PdfAnalyzer
