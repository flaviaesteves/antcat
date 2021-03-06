Then(/^the reference section should be "(.*)"$/) do |reference|
  first('.reference_sections .reference_section')
    .find('div.display').text.should =~ /#{reference}\.?/
end

When(/^I click the reference section/) do
  first('.reference_sections .reference_section').find('div.display').click
end

When(/^I fill in the references field with "([^"]*)"$/) do |references|
  step %{I fill in "references_taxt" with "#{references}"}
end

When(/^I save the reference section$/) do
  within first('.reference_sections .reference_section') do
    step %{I press "Save"}
  end
end

When(/^I delete the reference section$/) do
  within first('.reference_section') do
    step %{I press "Delete"}
  end
end

Then(/^the reference section should be empty$/) do
  page.should_not have_css '.reference_sections .reference_section'
end

When(/^I cancel the reference section's changes$/) do
  within first('.reference_sections .reference_section') do
    step %{I press the "Cancel" button}
  end
end

When(/^I click the "Add" reference section button$/) do
  within '.references_section' do
    click_button 'Add'
  end
end

Then(/^I should (not )?see the "Delete" button for the reference/) do |should_not|
  selector = should_not ? :should_not : :should
  visible = should_not ? :false : :true
  page.send selector, have_css('button.delete', visible: visible)
end
