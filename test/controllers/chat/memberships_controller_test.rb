require "test_helper"

class Chat::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @outsider = users(:two)
    @member = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Owner's Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @member, role: "member", default_postable: profiles(:stray))
  end

  test "edit is available to a member who isn't the owner" do
    sign_in_as @member
    get edit_chat_server_membership_path(@server)
    assert_response :success
  end

  test "edit is available to the owner too" do
    sign_in_as @owner
    get edit_chat_server_membership_path(@server)
    assert_response :success
  end

  test "edit is blocked for a non-member" do
    sign_in_as @outsider
    get edit_chat_server_membership_path(@server)
    assert_redirected_to join_chat_server_path(@server)
    assert_equal "Join this server first.", flash[:alert]
  end

  test "update lets a member change their own default postable" do
    sign_in_as @member
    patch chat_server_membership_path(@server), params: { default_postable_type: "Profile", default_postable_id: profiles(:ember).id }
    assert_redirected_to chat_server_path(@server)
    assert_equal profiles(:ember), @server.memberships.find_by(user: @member).default_postable
  end

  test "update does not touch the owner's default postable when a member updates their own" do
    sign_in_as @member
    patch chat_server_membership_path(@server), params: { default_postable_type: "Profile", default_postable_id: profiles(:ember).id }
    assert_equal profiles(:alice), @server.memberships.find_by(user: @owner).default_postable
  end

  test "update leaves the default postable alone and warns when the id doesn't resolve" do
    sign_in_as @member
    patch chat_server_membership_path(@server), params: { default_postable_type: "Profile", default_postable_id: "" }
    assert_redirected_to chat_server_path(@server)
    assert_equal "Couldn't update your default post as.", flash[:alert]
    assert_nil flash[:notice]
    assert_equal profiles(:stray), @server.memberships.find_by(user: @member).default_postable
  end

  test "edit does not raise when the owner has no membership row" do
    server = @owner.owned_chat_servers.create!(name: "Membership-less Server")
    sign_in_as @owner
    get edit_chat_server_membership_path(server)
    assert_response :success
  end

  test "update does not raise and warns when the owner has no membership row" do
    server = @owner.owned_chat_servers.create!(name: "Membership-less Server")
    sign_in_as @owner
    patch chat_server_membership_path(server), params: { default_postable_type: "Profile", default_postable_id: profiles(:alice).id }
    assert_redirected_to chat_server_path(server)
    assert_equal "Couldn't update your default post as.", flash[:alert]
  end

  test "update rejects a profile that belongs to someone else" do
    sign_in_as @member
    patch chat_server_membership_path(@server), params: { default_postable_type: "Profile", default_postable_id: profiles(:alice).id }
    assert_redirected_to chat_server_path(@server)
    assert_equal profiles(:stray), @server.memberships.find_by(user: @member).default_postable
  end

  test "update is blocked for a non-member" do
    sign_in_as @outsider
    patch chat_server_membership_path(@server), params: { default_postable_type: "Profile", default_postable_id: profiles(:carol).id }
    assert_redirected_to join_chat_server_path(@server)
  end
end
