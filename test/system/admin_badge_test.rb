require "application_system_test_case"

class AdminBadgeTest < ApplicationSystemTestCase
  test "admin badge is visible in the header when signed in as an admin" do
    sign_in_via_browser(users(:one))
    assert users(:one).admin?
    assert_selector ".admin-badge", text: "ADMIN"
  end

  test "admin badge is not visible when signed in as a non-admin" do
    sign_in_via_browser(users(:two))
    assert_not users(:two).admin?
    assert_no_selector ".admin-badge"
  end

  private

  def sign_in_via_browser(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "Plur4l!Pr0files#2026"
    click_button "Sign in"
    assert_current_path root_path
  end
end
