@javascript
Feature: Deleting a taxon
  As an editor of AntCat
  I want to delete taxa
  So that information is kept accurate
  So people use AntCat

  Background:
    Given these references exist
      | authors | citation   | title | year |
      | Fisher  | Psyche 3:3 | Ants  | 2004 |
      * there is a subfamily "Formicinae"
      * I log in
      * there is a genus "Eciton"
      * I go to the catalog page for "Formicinae"
      * I press "Edit"
      * I press "Add genus"
      * I click the name field
      * I set the name to "Atta"
      * I press "OK"
      * I click the protonym name field
      * I set the protonym name to "Eciton"
      * I press "OK"
      * I click the authorship field
      * I search for the author "Fisher"
      * I click the first search result
      * I press "OK"
      * I click the type name field
      * I set the type name to "Atta major"
      * I press "OK"
      * I press "Add this name"
      * I save my changes

  Scenario: Deleting a taxon that was just added
    When I press "Edit"
    And I will confirm on the next step
    And I press "Delete"
    Then I should be on the catalog page for "Formicinae"

  Scenario: Can't delete if taxon has stuff hanging off of it
    When I press "Edit"
    And I add a history item
    And I will confirm on the next step
    And I press "Delete"
    Then I should see "This taxon already has additional information attached to it."
