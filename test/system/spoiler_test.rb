require "application_system_test_case"

class SpoilerTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
  end

  test "clicking a spoiler reveals it" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Spoiler Tester"
    fill_in "Description", with: "the password is ||super secret||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"

    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_text "super secret"
  end

  test "clicking a revealed spoiler hides it again" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Toggle Tester"
    fill_in "Description", with: "||hidden text||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"

    spoiler.click
    assert_no_selector ".spoiler.spoiler--revealed"
  end

  test "multiline spoiler is fully revealed on click" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Multiline Tester"
    fill_in "Description", with: "||line one\nline two||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"

    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_text "line one"
    assert_text "line two"
  end

  test "spoiler inside code block is not converted" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Code Tester"
    fill_in "Description", with: "Use <code>||text||</code> for spoilers"
    click_button "Create profile"
    assert_text "Profile created."

    assert_selector "code", text: "||text||"
    assert_no_selector "code .spoiler"
  end

  private

  def sign_in_via_browser
    visit new_session_path
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "Plur4l!Pr0files#2026"
    click_button "Sign in"
    assert_current_path root_path
  end
end
