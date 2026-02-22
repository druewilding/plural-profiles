require "application_system_test_case"

class AuthenticationFlowsTest < ApplicationSystemTestCase
  test "sign in and sign out" do
    visit new_session_path
    fill_in "Email address", with: users(:one).email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
    assert_text "Plural Profiles" # wait for the home page to load
    assert_selector ".site-header a", text: "Sign out"

    within(".site-header") { click_link "Sign out" }
    assert_current_path new_session_path
  end

  test "sign in with wrong password shows error" do
    visit new_session_path
    fill_in "Email address", with: users(:one).email_address
    fill_in "Password", with: "wrongpassword"
    click_button "Sign in"

    assert_text "Try another email address or password"
  end

  test "register a new account" do
    visit new_registration_path
    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Sign up"

    assert_text "Account created"
  end
end
