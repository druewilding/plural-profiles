require "test_helper"

class Chat::ServerTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
  end

  test "valid with a name and owner" do
    server = Chat::Server.new(name: "Test Server", owner: @owner)
    assert server.valid?
  end

  test "requires a name" do
    server = Chat::Server.new(owner: @owner)
    assert_not server.valid?
    assert_includes server.errors[:name], "can't be blank"
  end

  test "generates a uuid on create" do
    server = Chat::Server.create!(name: "Test Server", owner: @owner)
    assert server.uuid.present?
  end

  test "uuid is unique" do
    server = Chat::Server.create!(name: "Test Server", owner: @owner)
    dupe = Chat::Server.new(name: "Other", owner: @owner, uuid: server.uuid)
    assert_not dupe.valid?
    assert_includes dupe.errors[:uuid], "has already been taken"
  end

  test "to_param returns the uuid" do
    server = Chat::Server.create!(name: "Test Server", owner: @owner)
    assert_equal server.uuid, server.to_param
  end

  test "two servers owned by the same user can share a name" do
    Chat::Server.create!(name: "Same Name", owner: @owner)
    other = Chat::Server.new(name: "Same Name", owner: @owner)
    assert other.valid?
  end

  test "destroying a server destroys its memberships and channels" do
    server = Chat::Server.create!(name: "Test Server", owner: @owner)
    server.memberships.create!(user: @owner, role: "owner")
    channel = server.channels.create!(name: "general")

    server.destroy

    assert_raises(ActiveRecord::RecordNotFound) { channel.reload }
    assert_empty Chat::Membership.where(server_id: server.id)
  end
end
