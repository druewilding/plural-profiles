require "test_helper"

class Chat::ServerInviteTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
  end

  test "generates a token on create" do
    invite = @server.server_invites.create!(created_by: @owner)
    assert invite.token.present?
  end

  test "token is unique" do
    invite = @server.server_invites.create!(created_by: @owner)
    dupe = Chat::ServerInvite.new(server: @server, created_by: @owner, token: invite.token)
    assert_not dupe.valid?
    assert_includes dupe.errors[:token], "has already been taken"
  end

  test "unredeemed scope returns only invites with no redeemed_by" do
    unredeemed = @server.server_invites.create!(created_by: @owner)
    redeemed = @server.server_invites.create!(created_by: @owner)
    redeemed.redeem!(users(:two))

    assert_includes Chat::ServerInvite.unredeemed, unredeemed
    assert_not_includes Chat::ServerInvite.unredeemed, redeemed
  end

  test "redeemed? returns correct status" do
    invite = @server.server_invites.create!(created_by: @owner)
    assert_not invite.redeemed?

    invite.redeem!(users(:two))
    assert invite.redeemed?
  end

  test "redeem! sets redeemed_by and redeemed_at" do
    invite = @server.server_invites.create!(created_by: @owner)
    redeemer = users(:two)

    invite.redeem!(redeemer)
    invite.reload

    assert_equal redeemer, invite.redeemed_by
    assert invite.redeemed_at.present?
  end

  test "redeem! raises on a second redemption attempt" do
    invite = @server.server_invites.create!(created_by: @owner)
    invite.redeem!(users(:two))

    assert_raises(ActiveRecord::RecordInvalid) do
      invite.redeem!(@owner)
    end
  end

  test "to_param returns the token" do
    invite = @server.server_invites.create!(created_by: @owner)
    assert_equal invite.token, invite.to_param
  end

  test "destroying the server destroys its invites" do
    invite = @server.server_invites.create!(created_by: @owner)
    @server.destroy
    assert_raises(ActiveRecord::RecordNotFound) { invite.reload }
  end
end
