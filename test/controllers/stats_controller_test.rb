require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get stats_path
    assert_redirected_to new_session_path
  end

  test "shows stats when authenticated as admin" do
    sign_in_as users(:one)
    get stats_path
    assert_response :success
    assert_select "h1", "Stats"
    assert_select ".stats-card", minimum: 1
  end

  test "redirects non-admins" do
    sign_in_as users(:two)
    get stats_path
    assert_redirected_to root_path
  end
end
