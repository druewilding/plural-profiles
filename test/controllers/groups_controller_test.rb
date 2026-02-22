require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  test "show displays public group by uuid" do
    group = groups(:friends)
    get group_path(uuid: group.uuid)
    assert_response :success
    assert_match "Friends", response.body
  end

  test "show lists group profiles" do
    group = groups(:friends)
    get group_path(uuid: group.uuid)
    assert_response :success
    assert_match "Alice", response.body
  end

  test "show works when logged in" do
    sign_in_as users(:one)
    group = groups(:friends)
    get group_path(uuid: group.uuid)
    assert_response :success
  end

  test "show returns 404 for unknown uuid" do
    get group_path(uuid: "nonexistent-uuid")
    assert_response :not_found
  end

  test "show displays sub-group names as headings" do
    everyone = groups(:everyone)
    get group_path(uuid: everyone.uuid)
    assert_response :success
    assert_match "Friends", response.body
  end

  test "show includes profiles from sub-groups inline" do
    everyone = groups(:everyone)
    get group_path(uuid: everyone.uuid)
    assert_response :success
    # Alice is in friends, which is a child of everyone
    assert_match "Alice", response.body
  end

  test "show recurses deeply into nested sub-groups" do
    user = users(:one)
    everyone = groups(:everyone)
    friends = groups(:friends)

    # Build: everyone → friends → close_friends → alice
    close_friends = user.groups.create!(name: "Close Friends")
    GroupGroup.create!(parent_group: friends, child_group: close_friends)
    close_friends.profiles << profiles(:alice)

    get group_path(uuid: everyone.uuid)
    assert_response :success
    assert_match "Close Friends", response.body
    assert_match "Alice", response.body
  end

  test "show links sub-group profiles through their own group" do
    everyone = groups(:everyone)
    friends = groups(:friends)
    alice = profiles(:alice)

    get group_path(uuid: everyone.uuid)
    assert_response :success
    # Profile card should link through friends (the group Alice belongs to), not everyone
    assert_match group_profile_path(friends.uuid, alice.uuid), response.body
  end

  test "show hides Other profiles heading when no direct profiles" do
    everyone = groups(:everyone)
    get group_path(uuid: everyone.uuid)
    assert_response :success
    assert_no_match "Other profiles", response.body
  end
end
