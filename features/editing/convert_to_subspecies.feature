@javascript
Feature: Converting a species to a subspecies
  As an editor of AntCat
  I want to make a species a subspecies
  So the data is correct

  Scenario: Converting a species to a subspecies when its protonym already has the right name
    Given there is a species "Camponotus dallatorei" with genus "Camponotus"
    And there is a species "Camponotus alii" with genus "Camponotus"
    And I am logged in
    When I go to the edit page for "Camponotus dallatorei"
    And I press "Convert to subspecies"
    Then I should be on the "Convert to subspecies" page for "Camponotus dallatorei"
    When I click the new species field
    And I set the new species field to "Camponotus alii"
    And I press "OK"
    And I press "OK"
    Then I should be on the catalog page for "Camponotus alii dallatorei"

  Scenario: Converting a species to a subspecies when it already exists

  Scenario: Only show button if showing a species
    Given there is a subspecies "Camponotus dallatorei alii"
    And I am logged in
    When I go to the edit page for "Camponotus dallatorei alii"
    Then I should not see "Convert to subspecies"
