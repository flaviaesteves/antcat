@javascript
Feature: Editing a taxon
  As an editor of AntCat
  I want to edit taxa
  So that information is kept accurate
  So people use AntCat

  Scenario: Trying to edit without being logged in
    Given there is a genus called "Calyptites"
    When I go to the edit page for "Calyptites"
    And I set the name to "Atta"
    And I save the form
    Then I should be on the login page
    And I should see "Please log in before continuing"

  Scenario: Editing a family
    Given there is a family called "Formicidae"
    And I log in
    When I go to the edit page for "Formicidae"
    And I set the name to "Formica"
    And I save the form
    Then I should see "Formica" in the header

  Scenario: Trying to enter a blank name
    Given there is a genus called "Calyptites"
    And I log in
    When I go to the edit page for "Calyptites"
    And I set the name to ""
    And I save the form
    Then I should see "Name can't be blank"

  Scenario: Setting a genus's name to an existing one
    Given there is a genus called "Calyptites"
    And there is a genus called "Atta"
    And I log in
    When I go to the edit page for "Atta"
    And I set the name to "Calyptites"
    And I save the form
    Then I should see "This name is in use by another taxon"
    When I press "Save Homonym"
    Then there should be two genera with the name "Calyptites"

  Scenario: Leaving a genus name alone when there are already two homonyms
    Given there are two genera called "Calyptites"
    And I log in
    When I go to the edit page for "Calyptites"
    And I save the form
    Then I should not see "This name is in use by another taxon"
    Then I should see "Calyptites" in the header

  #Scenario: Changing taxt (regression)
    #Given there is a genus called "Atta"
    #And there is a genus called "Eciton"
    #And I log in
    #When I go to the page for "Atta"
    #Then I should not see "Eciton"
    #When I press "Edit"
    #And I put the cursor in the headline notes edit box
    #And I press "Insert Taxon"
    #Then I should not be on the page for "Atta"
    #And I fill in the name with "Eciton"
    #And I press "OK"
    #Then I should not be on the page for "Atta"

  #@flickerer
  #Scenario: Changing reference in taxt (regression)
    #Given there is a genus called "Atta"
    #And there is a genus called "Eciton"
    #And I log in
    #When I go to the page for "Atta"
    #Then I should not see "Eciton"
    #When I press "Edit"
    #And I put the cursor in the headline notes edit box
    #And I press "Insert Reference"
    #And I press "OK"
    #Then I should not be on the page for "Atta"

  Scenario: Cancelling
    Given there is a genus called "Calyptites"
    And I log in
    When I go to the edit page for "Calyptites"
    And I set the name to "Atta"
    And I press "Cancel"
    Then I should not see "Atta" in the header

  Scenario: Changing the protonym name
    Given there is a genus called "Atta" with a protonym name of "Atta"
    And there is a genus called "Eciton"
    And I log in
    When I go to the edit page for "Atta"
    And I click the name field
    And I set the protonym name to "Eciton"
    And I press "OK"
    And I save the form
    Then I should see "Eciton" in the headline

  Scenario: Changing the authorship
    Given these references exist
      | authors | citation   | title | year |
      | Fisher  | Psyche 3:3 | Ants  | 2004 |
    Given there is a genus called "Eciton"
    And I log in
    When I go to the edit page for "Eciton"
    And I click the authorship field
    And I search for the author "Fisher"
    And I click the first search result
    And I press "OK"
    Then the authorship field should contain "Fisher 2004. Ants. Psyche 3:3."
    When I save the form
    Then I should see "Fisher 2004. Ants. Psyche 3:3." in the headline
