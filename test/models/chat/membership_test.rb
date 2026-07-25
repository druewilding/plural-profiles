require "test_helper"

class Chat::MembershipTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
  end

  test "valid with a member role and no default profile" do
    membership = @server.memberships.new(user: users(:two), role: "member")
    assert membership.valid?
  end

  test "role must be owner or member" do
    membership = @server.memberships.new(user: @owner, role: "admin")
    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "user is unique per server" do
    @server.memberships.create!(user: @owner, role: "owner")
    dupe = @server.memberships.new(user: @owner, role: "member")
    assert_not dupe.valid?
    assert_includes dupe.errors[:user_id], "has already been taken"
  end

  test "the same user can be a member of different servers" do
    @server.memberships.create!(user: @owner, role: "owner")
    other_server = Chat::Server.create!(name: "Other Server", owner: users(:two))
    membership = other_server.memberships.new(user: @owner, role: "member")
    assert membership.valid?
  end

  test "default_profile must belong to the same user" do
    membership = @server.memberships.new(user: @owner, role: "owner", default_profile: profiles(:carol))
    assert_not membership.valid?
    assert_includes membership.errors[:default_profile], "must belong to the same user"
  end

  test "default_profile belonging to the same user is valid" do
    membership = @server.memberships.new(user: @owner, role: "owner", default_profile: profiles(:alice))
    assert membership.valid?
  end

  test "owner? is true only for the owner role" do
    owner_membership = @server.memberships.create!(user: @owner, role: "owner")
    member_membership = @server.memberships.create!(user: users(:two), role: "member")

    assert owner_membership.owner?
    assert_not member_membership.owner?
  end
end
