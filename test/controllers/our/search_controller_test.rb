require "test_helper"

class Our::SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # The sidebar (rendered via OurSidebar on every "our" page) always lists ALL
  # of the user's groups and profiles for navigation, regardless of the search
  # query — and the search form echoes the query back into its input value —
  # so assertions must be scoped to just the results area to avoid false
  # positives/negatives from that noise.
  def main_content
    doc = Nokogiri::HTML5(response.body)
    doc.at_css(".main-content form")&.remove
    doc.at_css(".main-content").to_html
  end

  test "show redirects unauthenticated user" do
    get our_search_path
    assert_redirected_to new_session_path
  end

  test "show with no query renders empty state without results" do
    sign_in_as @user
    get our_search_path
    assert_response :success
    assert_no_match "Alice", main_content
    assert_no_match "Friends", main_content
  end

  test "show matches profile by name" do
    sign_in_as @user
    get our_search_path, params: { q: "Alice" }
    assert_response :success
    assert_match "Alice", main_content
    assert_no_match "Bob", main_content
  end

  test "show matches profile by pronouns" do
    sign_in_as @user
    get our_search_path, params: { q: "he/him" }
    assert_response :success
    assert_match "Bob", main_content
    assert_no_match "Alice", main_content
  end

  test "show matches profile by description" do
    sign_in_as @user
    get our_search_path, params: { q: "painting" }
    assert_response :success
    assert_match "Alice", main_content
    assert_no_match "Bob", main_content
  end

  test "show matches group by name" do
    sign_in_as @user
    get our_search_path, params: { q: "Friends" }
    assert_response :success
    assert_match "Friends", main_content
    assert_no_match "Everyone Profile", main_content
  end

  test "show matches group by description" do
    sign_in_as @user
    get our_search_path, params: { q: "close friends" }
    assert_response :success
    assert_match "Friends", main_content
  end

  test "show matches by label" do
    sign_in_as @user
    profiles(:alice).update!(labels: [ "close-friends-only" ])
    get our_search_path, params: { q: "close-friends" }
    assert_response :success
    assert_match "Alice", main_content
    assert_no_match "Bob", main_content
  end

  test "show does not include other users' groups or profiles" do
    sign_in_as @user
    # "they/them" matches both the current user's own profile and Carol's
    # (owned by another user) — only the former should ever be returned.
    get our_search_path, params: { q: "they/them" }
    assert_response :success
    assert_match "Everyone Profile", main_content
    assert_no_match "Carol", main_content
  end

  test "show renders separate sections for groups and profiles" do
    sign_in_as @user
    get our_search_path, params: { q: "e" }
    assert_response :success
    assert_match "Groups", main_content
    assert_match "Profiles", main_content
  end
end
