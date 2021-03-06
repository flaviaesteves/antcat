Given(/this user exists/) do |table|
  table.hashes.each { |hash| User.create! hash }
end

When(/^I fill in the email field with "([^"]+)"$/) do |string|
  step %{I fill in "user_email" with "#{string}"}
end

When(/^I fill in the email field with my email address$/) do
  user = User.find_by_name 'Mark Wilden'
  step %{I fill in "user_email" with "#{user.email}"}
end

When(/^I fill in the password field with "([^"]+)"$/) do |string|
  step %{I fill in "user_password" with "#{string}"}
end

When(/^I press the first "([^"]+)" to log in$/) do |string|
  step %{I press the first "#{string}"}
end

Given('I am not logged in') do
end

def login_programmatically user
  login_as user
  # TODO move to individual scenarios. Many scenarios bypassed the main page
  # by directly visiting other paths.
  step 'I go to the main page'
end

# TODO not used
def login_through_web_page
  step 'I go to the main page'
  click_link "Login"
  step %{I fill in "user_email" with "#{user.email}"}
  step %{I fill in "user_password" with "#{user.password}"}
  step %{I press "Go" within "#login"}
end

When(/^I log in$/) do
  user = Feed::Activity.without_tracking do
    create :user, can_edit: true
  end
  login_programmatically user
end

Given('I am logged in') do
  step 'I log in'
end

When(/^I log in as a catalog editor(?: named "([^"]+)")?$/) do |name|
  name = "Quintus Batiatus" if name.blank?
  user = Feed::Activity.without_tracking do
    create :user, can_edit: true, name: name
  end
  login_programmatically user
end

When(/^I log in as a superadmin(?: named "([^"]+)")?$/) do |name|
  name = "Quintus Batiatus" if name.blank?
  user = Feed::Activity.without_tracking do
    create :user, can_edit: true, is_superadmin: true, name: name
  end
  login_programmatically user
end

When(/^I log in as a bibliography editor$/) do
  user = Feed::Activity.without_tracking do
    create :user
  end
  login_programmatically user
end

Then(/^there should be a mailto link to the email of "([^"]+)"$/) do |user_name|
  # Problems with this are caused by having @ or : in the target of the search
  #user_email = User.find_by_name(user_name).email
  #page.should have_css user_email
end
