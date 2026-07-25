require "test_helper"
require "turbo/broadcastable/test_helper"

class Chat::MessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @owner = users(:one)
    @other_member = users(:two)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
    @server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
    @server.memberships.create!(user: @other_member, role: "member", default_profile: profiles(:carol))
    @channel = @server.channels.create!(name: "general")
  end

  test "requires a body" do
    message = @channel.messages.new(user: @owner, profile: profiles(:alice))
    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "requires a profile on create when none can be resolved" do
    outsider = users(:three)
    message = @channel.messages.new(user: outsider, body: "hi")
    assert_not message.valid?
    assert_includes message.errors[:profile_id], "can't be blank"
  end

  test "falls back to the server membership's default profile when there is no channel override" do
    message = @channel.messages.create!(user: @owner, body: "hello")
    assert_equal profiles(:alice), message.profile
    assert_equal profiles(:alice).name, message.profile_name
  end

  test "a channel-specific default profile overrides the server default" do
    @channel.channel_default_profiles.create!(user: @owner, profile: profiles(:bob))
    message = @channel.messages.create!(user: @owner, body: "hello")
    assert_equal profiles(:bob), message.profile
  end

  test "chat proxy brackets in the body select a different profile and strip the prefix" do
    profiles(:bob).update!(chat_bracket_before: "bob:")
    message = @channel.messages.create!(user: @owner, body: "bob: taking over for a sec")

    assert_equal profiles(:bob), message.profile
    assert_equal "taking over for a sec", message.body
  end

  test "an explicitly assigned profile is not overridden by resolve_profile" do
    message = @channel.messages.create!(user: @owner, profile: profiles(:bob), body: "hello")
    assert_equal profiles(:bob), message.profile
  end

  test "before_cursor only returns messages strictly earlier than the given message" do
    first = travel_to(2.minutes.ago) { @channel.messages.create!(user: @owner, body: "first") }
    second = travel_to(1.minute.ago) { @channel.messages.create!(user: @owner, body: "second") }
    third = @channel.messages.create!(user: @owner, body: "third")

    earlier = @channel.messages.before_cursor(third).to_a
    assert_includes earlier, first
    assert_includes earlier, second
    assert_not_includes earlier, third
  end

  test "latest_page returns messages in ascending (oldest-first) order" do
    first = travel_to(2.minutes.ago) { @channel.messages.create!(user: @owner, body: "first") }
    second = travel_to(1.minute.ago) { @channel.messages.create!(user: @owner, body: "second") }
    third = @channel.messages.create!(user: @owner, body: "third")

    assert_equal [ first, second, third ], Chat::Message.latest_page(@channel.messages)
  end

  test "creating a message broadcasts an append to the channel's stream" do
    assert_turbo_stream_broadcasts @channel do
      @channel.messages.create!(user: @owner, body: "hello")
    end
  end

  test "creating a message broadcasts unread dots to other server members but not the author" do
    assert_turbo_stream_broadcasts [ @other_member, @server, :chat_channel_pane ] do
      @channel.messages.create!(user: @owner, body: "hello")
    end

    assert_no_turbo_stream_broadcasts [ @owner, @server, :chat_channel_pane ] do
      @channel.messages.create!(user: @owner, body: "hello again")
    end
  end
end
