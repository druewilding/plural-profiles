require "test_helper"

class Chat::ChannelDefaultPostableTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
    @channel = @server.channels.create!(name: "general")
  end

  test "valid with a profile belonging to the same user" do
    default = @channel.channel_default_postables.new(user: @owner, postable: profiles(:alice))
    assert default.valid?
  end

  test "valid with a group belonging to the same user" do
    default = @channel.channel_default_postables.new(user: @owner, postable: groups(:friends))
    assert default.valid?
  end

  test "postable must belong to the same user" do
    default = @channel.channel_default_postables.new(user: @owner, postable: profiles(:carol))
    assert_not default.valid?
    assert_includes default.errors[:postable], "must belong to the same user"
  end

  test "user is unique per channel" do
    @channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))
    dupe = @channel.channel_default_postables.new(user: @owner, postable: profiles(:bob))
    assert_not dupe.valid?
    assert_includes dupe.errors[:user_id], "has already been taken"
  end

  test "the same user can have different default postables in different channels" do
    @channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))
    other_channel = @server.channels.create!(name: "off-topic")
    default = other_channel.channel_default_postables.new(user: @owner, postable: profiles(:bob))
    assert default.valid?
  end

  test "updating the postable on an existing default is allowed" do
    default = @channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))
    default.postable = profiles(:bob)
    assert default.valid?
  end

  test "switching the postable from a profile to a group is allowed" do
    default = @channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))
    default.postable = groups(:friends)
    assert default.valid?
  end
end
