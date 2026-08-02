require "test_helper"
require "turbo/broadcastable/test_helper"

class Chat::MessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @owner = users(:one)
    @other_member = users(:two)
    @server = Chat::Server.create!(name: "Test Server", owner: @owner)
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @other_member, role: "member", default_postable: profiles(:carol))
    @channel = @server.channels.create!(name: "general")
  end

  test "requires a body" do
    message = @channel.messages.new(user: @owner, postable: profiles(:alice))
    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "requires a postable on create when none can be resolved" do
    outsider = users(:three)
    message = @channel.messages.new(user: outsider, body: "hi")
    assert_not message.valid?
    assert_includes message.errors[:postable_id], "can't be blank"
  end

  test "falls back to the server membership's default postable when there is no channel override" do
    message = @channel.messages.create!(user: @owner, body: "hello")
    assert_equal profiles(:alice), message.postable
    assert_equal profiles(:alice).name, message.postable_name
  end

  test "a channel-specific default postable overrides the server default" do
    @channel.channel_default_postables.create!(user: @owner, postable: profiles(:bob))
    message = @channel.messages.create!(user: @owner, body: "hello")
    assert_equal profiles(:bob), message.postable
  end

  test "chat proxy brackets in the body select a different profile and strip the prefix" do
    profiles(:bob).update!(chat_bracket_before: "bob:")
    message = @channel.messages.create!(user: @owner, body: "bob: taking over for a sec")

    assert_equal profiles(:bob), message.postable
    assert_equal "taking over for a sec", message.body
  end

  test "chat proxy brackets can select a group instead of a profile" do
    groups(:friends).update!(chat_bracket_before: "friends:")
    message = @channel.messages.create!(user: @owner, body: "friends: we're all here")

    assert_equal groups(:friends), message.postable
    assert_equal "we're all here", message.body
  end

  test "a channel-specific default postable can be a group" do
    @channel.channel_default_postables.create!(user: @owner, postable: groups(:friends))
    message = @channel.messages.create!(user: @owner, body: "hello")
    assert_equal groups(:friends), message.postable
  end

  test "an explicitly assigned postable is not overridden by resolve_postable" do
    message = @channel.messages.create!(user: @owner, postable: profiles(:bob), body: "hello")
    assert_equal profiles(:bob), message.postable
  end

  test "an explicitly assigned postable is not overridden even when the body matches another profile's chat proxy brackets" do
    profiles(:bob).update!(chat_bracket_before: "bob:")
    message = @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "bob: taking over for a sec")

    assert_equal profiles(:alice), message.postable
    assert_equal "bob: taking over for a sec", message.body
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

  test "the broadcasted message partial renders without a request context and without crashing" do
    # Current.user is nil here (this is a plain model test, not a request) —
    # same situation as a message created from a script. The popover
    # trigger's URL is built straight from the postable's own class/uuid,
    # not through any Current.user-dependent helper, so this must render
    # without crashing.
    assert_nil Current.user

    streams = capture_turbo_stream_broadcasts @channel do
      @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "hello")
    end

    html = streams.first.to_html
    helpers = Rails.application.routes.url_helpers
    assert_match helpers.chat_mini_profile_path("Profile", profiles(:alice).uuid), html
  end

  test "the broadcasted message partial renders a group postable without crashing" do
    assert_nil Current.user
    group = groups(:friends).tap { |g| g.update!(user: @owner) }

    streams = capture_turbo_stream_broadcasts @channel do
      @channel.messages.create!(user: @owner, postable: group, body: "hello")
    end

    html = streams.first.to_html
    helpers = Rails.application.routes.url_helpers
    assert_match helpers.chat_mini_profile_path("Group", group.uuid), html
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
