Feature: Request denial corrections
  As a claims specialist
  I want to retrieve denial corrections by remit/remark code tuples
  So that I can explain payer denials quickly

  Scenario: Looking up corrections for ERA tuples
    Given a denial rule exists with EOB code "125", group code "CO", reason code "29", and description "Denied. Bill was received after 90 days."
    And a denial rule exists with EOB code "157", group code "PR", reason code "96", and description "Not responsible for replacement of contacts."
    When I request corrections for the following tuples:
      | remit_code | remark_code |
      | CO29       | N211        |
      | PR96       |             |
    Then the API response should include a correction with code "125" and reason code "29"
    And the API response should include a correction with code "157" and reason code "96"
