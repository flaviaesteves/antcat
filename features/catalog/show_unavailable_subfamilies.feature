Feature: Showing/hiding unavailable subfamilies
  As a user of AntCat
  I want choose whether or not to take up screen space with unavailable subfamilies
  So I can see more useful information

  Background:
    Given the Formicidae family exists
    And subfamily "Availabledae" exists
    And the unavailable subfamily "Unavailabledae" exists

  Scenario: Unavailable subfamilies are initially hidden
    When I go to the catalog
    Then I should see "Availabledae"
    And I should not see "Unavailabledae"

  Scenario: Showing unavailable subfamilies
    When I go to the catalog
    And I follow "show invalid"
    Then I should see "Unavailabledae"
    And I should see "Availabledae"

    When I follow "show valid only"
    Then I should see "Availabledae"
    And I should not see "Unavailabledae"
