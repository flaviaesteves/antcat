# coding: UTF-8
# Reference picker
Then /I should (not )?see the reference picker/ do |should_not|
  selector = should_not ? :should_not : :should
  find('.antcat_reference_picker').send(selector, be_visible)
end

# Name picker
Then /in the results section I should see the editable taxt for "([^"]*)"/ do |text|
  within "#results" do
    step %{I should see "#{Taxt.to_editable_taxon(Taxon.find_by_name(text))}"}
  end
end

Then /in the results section I should see the editable taxt for the name "([^"]*)"/ do |text|
  within "#results" do
    step %{I should see "#{Taxt.to_editable_name(Name.find_by_name(text))}"}
  end
end

Then /in the results section I should see the id for "([^"]*)"/ do |text|
  within "#results" do
    step %{I should see "#{Name.find_by_name(text).id}"}
  end
end

Then /in the results section I should see the id for the name "([^"]*)"/ do |text|
  within "#results" do
    step %{I should see "#{Name.find_by_name(text).id}"}
  end
end

Then /in the name picker field display I should see the first name/ do
  within "#picker .display" do
    step %{I should see "#{Name.first.name}"}
  end
end

Then /in the name picker field display I should see "([^"]*)"/ do |text|
  within "#picker .display" do
    step %{I should see "#{text}"}
  end
end

Then /^I should (not )?see the name picker edit interface$/ do |should_not|
  selector = should_not ? :should_not : :should
  find('#picker .edit').send(selector, be_visible)
end

Then /^I should (not )?see the name picker$/ do |should_not|
  selector = should_not ? :should_not : :should
  find('.antcat_name_picker').send(selector, be_visible)
end

When /^I edit the reference$/ do
  within ".current" do
    step 'I follow "edit"'
  end
end

When /^I add a reference$/ do
  within ".expansion" do
    step 'I follow "Add"'
  end
end

When /^I set the authors to "([^"]*)"$/ do |names|
  within ".current div.edit" do
    step %{I fill in "reference[author_names_string]" with "#{names}"}
  end
end

When /^I set the title to "([^"]*)"$/ do |title|
  within ".current div.edit" do
    step %{I fill in "reference[title]" with "#{title}"}
  end
end

When /^I add a reference by Brian Fisher$/ do
  step 'I press "Add"'
  step %{I fill in "reference[author_names_string]" with "Fisher, B.L."}
  step %{I fill in "reference[title]" with "Between Pacific Tides"}
  step %{I fill in "reference_journal_name" with "Ants"}
  step %{I fill in "reference[series_volume_issue]" with "2"}
  step %{I fill in "article_pagination" with "1"}
  step %{I fill in "reference[citation_year]" with "1992"}
  step %{I save my changes}
end

When /In the search box, I press "Go"/ do
  step 'I press "Go" within ".expansion"'
end

When /^I search for "([^"]*)"$/ do |search_term|
  # this is to make the selectmenu work
  step %{I follow "Search for"}
  step %{I follow "Search for"}
  step "I fill in the search box with \"#{search_term}\""
  step %{In the search box, I press "Go"}
end

When /^I search for the authors? "([^"]*)"$/ do |authors|
  step %{I follow "Search for author(s)"}
  step %{I fill in the search box with "#{authors}"}
  step %{In the search box, I press "Go"}
end
