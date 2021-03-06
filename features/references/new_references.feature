Feature: Seeing what's new
  As a user of AntCat
  I want to see recently added references
  So I can keep up with the state of the literature

  Background:
    Given these references exist
      | authors    | citation   | title             | created_at | updated_at | year | review_state |
      | Ward, P.   | Psyche 5:3 | Ward's World      | 2010-2-2   | 2010-1-1   | 2010 |              |
      | Bolton, B. | Psyche 4:2 | Bolton's Bulletin | 2010-1-1   | 2010-2-2   | 2010 | reviewing    |

  Scenario: See features in order of addition
    Given I am logged in

    When I go to the references page
    And I follow "Latest Additions"
    Then I should see these entries with a header in this order:
      | date       | entry                                          | review_state   |
      | 2010-02-02 | Ward, P. 2010. Ward's World. Psyche 5:3        |                |
      | 2010-01-01 | Bolton, B. 2010. Bolton's Bulletin. Psyche 4:2 | Being reviewed |

  Scenario: Start reviewing
    Given I am logged in

    When I go to the new references page
    And I click "Start reviewing" on the Ward reference
    Then the review status on the Ward reference should change to "Being reviewed"

  Scenario: Stop reviewing
    Given I am logged in

    When I go to the new references page
    And I click "Start reviewing" on the Ward reference
    And I go to the new references page
    And I click "Finish reviewing" on the Ward reference
    Then the review status on the Ward reference should change to "Reviewed"

  Scenario: Restart reviewing
    Given I am logged in

    When I go to the new references page
    And I click "Start reviewing" on the Ward reference
    And I click "Finish reviewing" on the Ward reference
    And I click "Restart reviewing" on the Ward reference
    And I go to the new references page
    Then the review status on the Ward reference should change to "Being reviewed"

  Scenario: Not a logged-in catalog editor
    Given I log in as a bibliography editor

    When I go to the new references page
    Then I should not see a "Start reviewing" button

  Scenario: Seeing the default reference button on the new references page
    Given I am logged in
    And the default reference is "Ward 2010"

    When I go to the new references page
    Then it should show "Ward 2010" as the default
    And it should not show "Bolton 1995" as the default

  Scenario: Changing the default reference button on the new references page
    Given I am logged in
    And there is no default reference

    When I go to the new references page
    And I click "Make default" on the Ward reference
    Given the default reference is "Ward 2010"
    And I go to the new references page
    Then it should show "Ward 2010" as the default
