Then(/^the taxt editor should contain the editable taxt for "(.*?)"$/) do |key|
  reference = find_reference_by_key key
  find('#name').value.strip.should == Taxt.to_editable_reference(reference)
end

# Seems like we need this now. Tests likely passed without this earlier
# because the code was slower, but I'm not sure.
#
# There is code for always showing the taxt editor buttons (eg "Insert
# Reference") in tests, like this: `@tag_buttons.show() if AntCat.testing`,
# but it seems like this code is not executed in time after a some unrelated
# code was removed.
#
# What this actually does: unfocus textarea and focus again.
And(/^I hack the taxt editor in test env$/) do
  find("#click_here_to_lose_focus").click
  find(".taxt_edit_box").click
end
