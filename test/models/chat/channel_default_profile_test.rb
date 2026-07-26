require "test_helper"

class Chat::ChannelDefaultProfileTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
    @channel = @server.channels.create!(name: "general")
  end

  test "valid with a profile belonging to the same user" do
    default = @channel.channel_default_profiles.new(user: @owner, profile: profiles(:alice))
    assert default.valid?
  end

  test "profile must belong to the same user" do
    default = @channel.channel_default_profiles.new(user: @owner, profile: profiles(:carol))
    assert_not default.valid?
    assert_includes default.errors[:profile], "must belong to the same user"
  end

  test "user is unique per channel" do
    @channel.channel_default_profiles.create!(user: @owner, profile: profiles(:alice))
    dupe = @channel.channel_default_profiles.new(user: @owner, profile: profiles(:bob))
    assert_not dupe.valid?
    assert_includes dupe.errors[:user_id], "has already been taken"
  end

  test "the same user can have different default profiles in different channels" do
    @channel.channel_default_profiles.create!(user: @owner, profile: profiles(:alice))
    other_channel = @server.channels.create!(name: "off-topic")
    default = other_channel.channel_default_profiles.new(user: @owner, profile: profiles(:bob))
    assert default.valid?
  end

  test "updating the profile on an existing default is allowed" do
    default = @channel.channel_default_profiles.create!(user: @owner, profile: profiles(:alice))
    default.profile = profiles(:bob)
    assert default.valid?
  end
end
