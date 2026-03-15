require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "show displays public profile by uuid" do
    profile = profiles(:alice)
    get profile_path(uuid: profile.uuid)
    assert_response :success
    assert_match "Alice", response.body
  end

  test "show works when logged in" do
    sign_in_as users(:one)
    profile = profiles(:alice)
    get profile_path(uuid: profile.uuid)
    assert_response :success
  end

  test "show returns 404 for unknown uuid" do
    get profile_path(uuid: "nonexistent-uuid")
    assert_response :not_found
  end

  test "show displays heart emojis on public profile" do
    profile = profiles(:alice)
    profile.update!(heart_emojis: %w[36_red_heart 22_violet_heart])
    get profile_path(uuid: profile.uuid)
    assert_response :success
    assert_match "36_red_heart.webp", response.body
    assert_match "22_violet_heart.webp", response.body
  end

  test "show applies profile theme CSS when profile has a theme" do
    profile = profiles(:alice) # has theme: dark_forest
    get profile_path(uuid: profile.uuid)
    assert_response :success
    # dark_forest theme has --page-bg: #0e2e24 — should appear in body style
    assert_match "--page-bg: #0e2e24", response.body
  end

  test "show uses site default CSS when profile has no theme" do
    profile = profiles(:bob) # no theme in fixture
    get profile_path(uuid: profile.uuid)
    assert_response :success
    # default_shared theme has --page-bg: #1a1a2e
    assert_match "--page-bg: #1a1a2e", response.body
  end

  test "show displays theme credit when profile has a theme" do
    profile = profiles(:alice) # has theme: dark_forest with credit
    get profile_path(uuid: profile.uuid)
    assert_response :success
    assert_match "theme-credit", response.body
    assert_match "Dark Forest", response.body
    assert_match "Verdant Studio", response.body
  end

  test "show does not display theme credit when profile has no theme" do
    profile = profiles(:bob)
    get profile_path(uuid: profile.uuid)
    assert_response :success
    assert_no_match "theme-credit", response.body
  end
end
