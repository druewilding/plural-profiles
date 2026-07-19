require "application_system_test_case"

class AccountSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
    click_link "Account"
  end

  # -- change email --

  test "submit new email shows verification message" do
    within(".card", text: "Change email") do
      fill_in "New email address", with: "newemail@example.com"
      click_button "Send verification email"
    end

    assert_text "Verification email sent to newemail@example.com"
  end

  test "submit same email shows error" do
    within(".card", text: "Change email") do
      fill_in "New email address", with: @user.email_address
      click_button "Send verification email"
    end

    assert_text "already your current email"
  end

  test "pending email change shows notice on account page" do
    within(".card", text: "Change email") do
      fill_in "New email address", with: "pending@example.com"
      click_button "Send verification email"
    end

    assert_text "Verification pending for"
    assert_text "pending@example.com"
  end

  test "cancel pending email change" do
    within(".card", text: "Change email") do
      fill_in "New email address", with: "pending@example.com"
      click_button "Send verification email"
    end

    assert_text "Verification pending"
    click_link "Cancel"

    assert_text "Email change cancelled"
    assert_no_text "Verification pending"
  end

  # -- change password --

  test "change password successfully" do
    within(".card", text: "Change password") do
      fill_in "Current password", with: "Plur4l!Pr0files#2026"
      fill_in "New password", with: "BrandN3w!Pass#2026"
      fill_in "Confirm new password", with: "BrandN3w!Pass#2026"
      click_button "Update password"
    end

    assert_text "Password updated."
  end

  test "change password with wrong current password shows error" do
    within(".card", text: "Change password") do
      fill_in "Current password", with: "wrong-password"
      fill_in "New password", with: "BrandN3w!Pass#2026"
      fill_in "Confirm new password", with: "BrandN3w!Pass#2026"
      click_button "Update password"
    end

    assert_text "Current password is incorrect"
  end

  test "change password fields enforce minimum length" do
    within(".card", text: "Change password") do
      assert_selector "input[minlength='8']#password"
      assert_selector "input[minlength='8']#password_confirmation"
    end
  end

  # -- time zone preference --

  test "set an explicit time zone preference" do
    within(".card", text: "Time zone") do
      select "London", from: "user_time_zone"
      click_button "Save time zone"
    end

    assert_text "Time zone updated."
    assert_equal "London", @user.reload.time_zone
  end

  test "browser time zone auto-detect cookie is set on page load" do
    cookie = page.driver.browser.manage.cookie_named("browser_time_zone")
    assert cookie, "Expected a browser_time_zone cookie to be set"
    assert cookie[:value].present?
  end

  test "clear time zone preference back to auto-detect" do
    @user.update!(time_zone: "London")
    visit our_account_path

    within(".card", text: "Time zone") do
      select "Auto-detect from browser", from: "user_time_zone"
      click_button "Save time zone"
    end

    assert_text "Time zone updated."
    assert_nil @user.reload.time_zone
  end

  # -- invite codes --

  test "generate invite code and see it on account page" do
    within(".card", text: "Invite codes") do
      click_button "Generate invite code"
    end

    assert_text "Invite code created"
    within(".card", text: "Invite codes") do
      assert_selector ".invite-code", minimum: 1
    end
  end

  test "invite codes from fixtures are visible" do
    within(".card", text: "Invite codes") do
      assert_text invite_codes(:available).code
    end
  end
end
