require "test_helper"

class Chat::ServersControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @outsider = users(:two)
    @server = @owner.owned_chat_servers.create!(name: "Owner's Server")
    @server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
  end

  test "index lists only servers the current user belongs to" do
    other_server = users(:two).owned_chat_servers.create!(name: "Someone Else's Server")
    other_server.memberships.create!(user: users(:two), role: "owner")

    sign_in_as @owner
    get chat_servers_path
    assert_response :success
    assert_match "Owner's Server", response.body
    assert_no_match "Someone Else's Server", response.body
  end

  test "show renders channels for a member" do
    @server.channels.create!(name: "general")
    sign_in_as @owner
    get chat_server_path(@server)
    assert_response :success
    assert_match "general", response.body
  end

  test "show redirects a non-member who isn't the owner to the join flow" do
    sign_in_as @outsider
    get chat_server_path(@server)
    assert_redirected_to join_chat_server_path(@server)
    assert_equal "Join this server first.", flash[:alert]
  end

  test "create builds the server and an owner membership with the chosen default profile" do
    sign_in_as @owner
    assert_difference [ "Chat::Server.count", "Chat::Membership.count" ], 1 do
      post chat_servers_path, params: {
        chat_server: { name: "New Server", subtitle: "A place to chat", default_profile_id: profiles(:bob).id }
      }
    end

    server = Chat::Server.order(:created_at).last
    assert_redirected_to chat_server_path(server)
    membership = server.memberships.find_by(user: @owner)
    assert_equal "owner", membership.role
    assert_equal profiles(:bob), membership.default_profile
  end

  test "create rejects a blank name" do
    sign_in_as @owner
    assert_no_difference "Chat::Server.count" do
      post chat_servers_path, params: { chat_server: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects a theme that doesn't belong to the user and isn't shared" do
    sign_in_as @owner
    assert_no_difference "Chat::Server.count" do
      post chat_servers_path, params: { chat_server: { name: "New Server", theme_id: themes(:other_user_theme).id } }
    end
    assert_response :unprocessable_entity
    assert_match "is not available", response.body
  end

  test "create accepts a shared theme" do
    sign_in_as @owner
    assert_difference "Chat::Server.count", 1 do
      post chat_servers_path, params: { chat_server: { name: "New Server", theme_id: themes(:ocean_shared).id } }
    end
  end

  test "edit is only accessible to the owner" do
    sign_in_as @outsider
    get edit_chat_server_path(@server)
    assert_redirected_to chat_server_path(@server)
    assert_equal "Only the server owner can do that.", flash[:alert]
  end

  test "update lets the owner change the name" do
    sign_in_as @owner
    patch chat_server_path(@server), params: { chat_server: { name: "Renamed Server" } }
    assert_redirected_to chat_server_path(@server)
    assert_equal "Renamed Server", @server.reload.name
  end

  test "update rejects a theme the owner doesn't have access to" do
    sign_in_as @owner
    patch chat_server_path(@server), params: { chat_server: { theme_id: themes(:other_user_theme).id } }
    assert_response :unprocessable_entity
    assert_not_equal themes(:other_user_theme), @server.reload.theme
  end

  test "update is blocked for a non-owner" do
    sign_in_as @outsider
    patch chat_server_path(@server), params: { chat_server: { name: "Hijacked" } }
    assert_redirected_to chat_server_path(@server)
    assert_not_equal "Hijacked", @server.reload.name
  end

  test "join redirects to profile creation when the user has no profiles" do
    profileless = users(:four)
    sign_in_as profileless
    get join_chat_server_path(@server)
    assert_redirected_to new_our_profile_path(return_to: join_chat_server_path(@server))
  end

  test "join redirects an existing member straight to the server" do
    sign_in_as @owner
    get join_chat_server_path(@server)
    assert_redirected_to chat_server_path(@server)
    assert_equal "You're already a member.", flash[:notice]
  end

  test "join without an invite token refuses to show the profile picker" do
    sign_in_as @outsider
    get join_chat_server_path(@server)
    assert_redirected_to chat_root_path
    assert_equal "You need a valid invite link to join this server.", flash[:alert]
  end

  test "join with an unknown invite token refuses to show the profile picker" do
    sign_in_as @outsider
    get join_chat_server_path(@server, invite_token: "not-a-real-token")
    assert_redirected_to chat_root_path
  end

  test "join with an already-redeemed invite token refuses to show the profile picker" do
    invite = @server.server_invites.create!(created_by: @owner)
    invite.redeem!(users(:four))

    sign_in_as @outsider
    get join_chat_server_path(@server, invite_token: invite.token)
    assert_redirected_to chat_root_path
  end

  test "join renders the profile picker for a non-member with a valid invite token" do
    invite = @server.server_invites.create!(created_by: @owner)
    sign_in_as @outsider
    get join_chat_server_path(@server, invite_token: invite.token)
    assert_response :success
    assert_match "Post as", response.body
  end

  test "join page does not leak the server's channel names to a non-member" do
    @server.channels.create!(name: "secret-plans")
    invite = @server.server_invites.create!(created_by: @owner)

    sign_in_as @outsider
    get join_chat_server_path(@server, invite_token: invite.token)
    assert_response :success
    assert_no_match "secret-plans", response.body
  end

  test "posting to join without an invite token does not create a membership" do
    sign_in_as @outsider
    assert_no_difference "Chat::Membership.count" do
      post join_chat_server_path(@server), params: { default_profile_id: profiles(:carol).id }
    end
    assert_redirected_to chat_root_path
  end

  test "posting to join with a valid invite token creates a membership and redeems the invite" do
    invite = @server.server_invites.create!(created_by: @owner)
    sign_in_as @outsider

    assert_difference "Chat::Membership.count", 1 do
      post join_chat_server_path(@server), params: { default_profile_id: profiles(:carol).id, invite_token: invite.token }
    end
    assert_redirected_to chat_server_path(@server)

    membership = @server.memberships.find_by(user: @outsider)
    assert_equal "member", membership.role
    assert_equal profiles(:carol), membership.default_profile
    assert invite.reload.redeemed?
    assert_equal @outsider, invite.redeemed_by
  end

  test "posting to join with someone else's already-redeemed invite token does not create a membership" do
    invite = @server.server_invites.create!(created_by: @owner)
    invite.redeem!(users(:four))

    sign_in_as @outsider
    assert_no_difference "Chat::Membership.count" do
      post join_chat_server_path(@server), params: { default_profile_id: profiles(:carol).id, invite_token: invite.token }
    end
    assert_redirected_to chat_root_path
  end
end
