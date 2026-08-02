require "test_helper"

class Chat::MiniProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @other = users(:two)
    @profile = profiles(:alice)
    @group = groups(:friends)
  end

  test "show renders the owner's edit link when the viewer owns the postable" do
    sign_in_as @owner
    get chat_mini_profile_path("Profile", @profile.uuid)
    assert_response :success
    assert_match "Edit profile", response.body
  end

  test "show renders a group's owner edit link" do
    sign_in_as @owner
    get chat_mini_profile_path("Group", @group.uuid)
    assert_response :success
    assert_match "Edit group", response.body
  end

  test "show renders no link for a non-owner when mini_profile_link_enabled is off" do
    assert_not @profile.mini_profile_link_enabled?
    sign_in_as @other
    get chat_mini_profile_path("Profile", @profile.uuid)
    assert_response :success
    assert_no_match "Edit profile", response.body
    assert_no_match "View full profile page", response.body
  end

  test "show renders the view-full-page link for a non-owner when mini_profile_link_enabled is on" do
    @profile.update!(mini_profile_link_enabled: true)
    sign_in_as @other
    get chat_mini_profile_path("Profile", @profile.uuid)
    assert_response :success
    assert_match "View full profile page", response.body
    assert_match profile_path(@profile.uuid), response.body
  end

  test "show reflects an overridden chat identity, not the full profile" do
    @profile.update!(mini_profile_pronouns_inherited: false, mini_profile_pronouns: "it/its")
    sign_in_as @owner
    get chat_mini_profile_path("Profile", @profile.uuid)
    assert_response :success
    assert_match "it/its", response.body
    assert_no_match @profile.pronouns, response.body
  end

  test "show 404s for an unknown uuid" do
    sign_in_as @owner
    get chat_mini_profile_path("Profile", "00000000-0000-0000-0000-000000000000")
    assert_response :not_found
  end

  test "show 404s for an invalid postable_type" do
    sign_in_as @owner
    # Built by hand: the route's own constraints: { postable_type: /Profile|Group/ }
    # means the path helper would raise UrlGenerationError before a request
    # is even made for anything else.
    get "/mini_profile/User/#{@profile.uuid}"
    assert_response :not_found
  end

  test "show redirects to sign-in when unauthenticated" do
    get chat_mini_profile_path("Profile", @profile.uuid)
    assert_redirected_to new_session_path
  end
end
