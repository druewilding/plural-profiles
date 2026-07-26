require "test_helper"

class Chat::InviteRedemptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @member = users(:two)
    @outsider = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @member, role: "member", default_postable: profiles(:carol))
    @invite = @server.server_invites.create!(created_by: @owner)
  end

  test "show renders the invite for someone who isn't a member yet" do
    sign_in_as @outsider
    get chat_invite_redemption_path(@invite.token)
    assert_response :success
    assert_match "Test Server", response.body
  end

  test "show does not leak the server's channel names to a non-member" do
    @server.channels.create!(name: "secret-plans")
    sign_in_as @outsider
    get chat_invite_redemption_path(@invite.token)
    assert_response :success
    assert_no_match "secret-plans", response.body
  end

  test "show redirects an already-redeemed invite as no longer valid" do
    @invite.redeem!(@member)
    sign_in_as @outsider

    get chat_invite_redemption_path(@invite.token)
    assert_redirected_to chat_root_path
    assert_equal "This invite link is no longer valid.", flash[:alert]
  end

  test "show redirects an unknown token as no longer valid" do
    sign_in_as @outsider
    get chat_invite_redemption_path("not-a-real-token")
    assert_redirected_to chat_root_path
    assert_equal "This invite link is no longer valid.", flash[:alert]
  end

  test "show redirects an existing member straight to the server" do
    sign_in_as @member
    get chat_invite_redemption_path(@invite.token)
    assert_redirected_to chat_server_path(@server)
    assert_equal "You're already a member.", flash[:notice]
  end
end
