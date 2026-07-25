require "test_helper"

class Chat::ChannelReadTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @server = Chat::Server.create!(name: "Test Server", owner: @user)
    @channel = @server.channels.create!(name: "general")
  end

  test "mark_read! creates a read row on first call" do
    assert_difference "Chat::ChannelRead.count", 1 do
      Chat::ChannelRead.mark_read!(@user, @channel)
    end

    read = Chat::ChannelRead.find_by(user: @user, channel: @channel)
    assert read.last_read_at.present?
  end

  test "mark_read! updates the existing row rather than creating a duplicate" do
    Chat::ChannelRead.mark_read!(@user, @channel)
    first_read_at = Chat::ChannelRead.find_by(user: @user, channel: @channel).last_read_at

    travel 1.minute do
      assert_no_difference "Chat::ChannelRead.count" do
        Chat::ChannelRead.mark_read!(@user, @channel)
      end
    end

    read = Chat::ChannelRead.find_by(user: @user, channel: @channel)
    assert_operator read.last_read_at, :>, first_read_at
  end

  test "channel_id is unique per user" do
    Chat::ChannelRead.create!(user: @user, channel: @channel, last_read_at: Time.current)
    dupe = Chat::ChannelRead.new(user: @user, channel: @channel, last_read_at: Time.current)

    assert_not dupe.valid?
    assert_includes dupe.errors[:channel_id], "has already been taken"
  end

  test "the same channel can be read by different users independently" do
    other_user = users(:two)
    Chat::ChannelRead.mark_read!(@user, @channel)

    assert_difference "Chat::ChannelRead.count", 1 do
      Chat::ChannelRead.mark_read!(other_user, @channel)
    end
  end
end
