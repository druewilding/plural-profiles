require "application_system_test_case"

class ProfileManagementTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
  end

  test "create a new profile" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Luna"
    fill_in "Pronouns", with: "she/they"
    fill_in "Description", with: "Hello, I'm Luna!"
    click_button "Create profile"

    assert_text "Profile created."
    assert_text "Luna"
    assert_text "she/they"
  end

  test "edit an existing profile" do
    visit our_profile_path(profiles(:alice))
    click_link "Edit"
    assert_current_path edit_our_profile_path(profiles(:alice))
    fill_in "Name", with: "Alice Updated"
    click_button "Update profile"

    assert_text "Profile updated."
    assert_text "Alice Updated"
  end

  test "delete a profile" do
    visit our_profile_path(profiles(:alice))
    accept_confirm do
      click_link "Delete"
    end

    assert_text "Profile deleted."
  end

  test "view own profile shows share link" do
    visit our_profile_path(profiles(:alice))
    assert_text "Share this profile"
  end

  test "subtitle appears on profile show page" do
    profiles(:alice).update!(subtitle: "the creative one")
    visit our_profile_path(profiles(:alice))
    assert_text "the creative one"
  end

  test "editing subtitle updates profile show page" do
    visit our_profile_path(profiles(:alice))
    click_link "Edit"
    fill_in "Subtitle", with: "morning person"
    click_button "Update profile"
    assert_text "morning person"
  end
end
