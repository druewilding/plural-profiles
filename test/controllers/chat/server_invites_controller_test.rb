require "test_helper"

class Chat::ServerInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @member = users(:two)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @member, role: "member", default_postable: profiles(:carol))
  end

  test "show creates a fresh invite when none exists yet" do
    sign_in_as @owner
    assert_difference "Chat::ServerInvite.count", 1 do
      get chat_server_invite_path(@server)
    end
    assert_response :success
  end

  test "show reuses the existing unredeemed invite rather than creating another" do
    invite = @server.server_invites.create!(created_by: @owner)
    sign_in_as @owner

    assert_no_difference "Chat::ServerInvite.count" do
      get chat_server_invite_path(@server)
    end
    assert_match invite.token, response.body
  end

  test "show is blocked for a non-owner member" do
    sign_in_as @member
    get chat_server_invite_path(@server)
    assert_redirected_to chat_server_path(@server)
    assert_equal "Only the server owner can do that.", flash[:alert]
  end

  test "create invalidates the previous unredeemed invite and makes a new one" do
    old_invite = @server.server_invites.create!(created_by: @owner)
    sign_in_as @owner

    post chat_server_invite_path(@server)

    assert_raises(ActiveRecord::RecordNotFound) { old_invite.reload }
    assert_equal 1, @server.server_invites.unredeemed.count
    assert_redirected_to chat_server_invite_path(@server)
  end

  test "create leaves a redeemed invite alone" do
    redeemed = @server.server_invites.create!(created_by: @owner)
    redeemed.redeem!(@member)

    sign_in_as @owner
    post chat_server_invite_path(@server)

    assert redeemed.reload.persisted?
  end

  test "create is blocked for a non-owner member" do
    sign_in_as @member
    assert_no_difference "Chat::ServerInvite.count" do
      post chat_server_invite_path(@server)
    end
    assert_redirected_to chat_server_path(@server)
  end
end
