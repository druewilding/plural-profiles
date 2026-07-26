require "test_helper"

class Chat::ChannelTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
  end

  test "valid with a name and server" do
    channel = @server.channels.new(name: "general")
    assert channel.valid?
  end

  test "requires a name" do
    channel = @server.channels.new
    assert_not channel.valid?
    assert_includes channel.errors[:name], "can't be blank"
  end

  test "generates a uuid on create" do
    channel = @server.channels.create!(name: "general")
    assert channel.uuid.present?
  end

  test "uuid is unique" do
    channel = @server.channels.create!(name: "general")
    dupe = Chat::Channel.new(server: @server, name: "other", uuid: channel.uuid)
    assert_not dupe.valid?
    assert_includes dupe.errors[:uuid], "has already been taken"
  end

  test "to_param returns the uuid" do
    channel = @server.channels.create!(name: "general")
    assert_equal channel.uuid, channel.to_param
  end

  test "name is unique within a server" do
    @server.channels.create!(name: "general")
    dupe = @server.channels.new(name: "general")
    assert_not dupe.valid?
    assert_includes dupe.errors[:name], "has already been taken"
  end

  test "the same channel name can be reused across different servers" do
    @server.channels.create!(name: "general")
    other_server = Chat::Server.create!(name: "Other Server", owner: @owner)
    channel = other_server.channels.new(name: "general")
    assert channel.valid?
  end

  test "destroying a channel destroys its messages" do
    channel = @server.channels.create!(name: "general")
    message = channel.messages.create!(user: @owner, postable: profiles(:alice), body: "hi")

    channel.destroy

    assert_raises(ActiveRecord::RecordNotFound) { message.reload }
  end

  test "default_postable_for returns the channel-specific override when set" do
    channel = @server.channels.create!(name: "general")
    channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))

    assert_equal profiles(:alice), channel.default_postable_for(@owner)
  end

  test "default_postable_for returns a group override when set" do
    channel = @server.channels.create!(name: "general")
    channel.channel_default_postables.create!(user: @owner, postable: groups(:friends))

    assert_equal groups(:friends), channel.default_postable_for(@owner)
  end

  test "default_postable_for returns nil when the user has no override" do
    channel = @server.channels.create!(name: "general")
    assert_nil channel.default_postable_for(@owner)
  end
end
