require "test_helper"

class Chat::ChannelDefaultPostablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @outsider = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @channel = @server.channels.create!(name: "general")
  end

  test "update creates a channel-specific default postable for the member" do
    sign_in_as @owner
    assert_difference "Chat::ChannelDefaultPostable.count", 1 do
      patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Profile", postable_uuid: profiles(:bob).uuid }
    end
    assert_redirected_to chat_server_channel_path(@server, @channel)
    assert_equal profiles(:bob), @channel.default_postable_for(@owner)
  end

  test "update accepts a group as the postable" do
    sign_in_as @owner
    assert_difference "Chat::ChannelDefaultPostable.count", 1 do
      patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Group", postable_uuid: groups(:friends).uuid }
    end
    assert_equal groups(:friends), @channel.default_postable_for(@owner)
  end

  test "update overwrites an existing default postable rather than duplicating it" do
    @channel.channel_default_postables.create!(user: @owner, postable: profiles(:alice))

    sign_in_as @owner
    assert_no_difference "Chat::ChannelDefaultPostable.count" do
      patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Profile", postable_uuid: profiles(:bob).uuid }
    end
    assert_equal profiles(:bob), @channel.default_postable_for(@owner)
  end

  test "update 404s for a profile that doesn't belong to the current user" do
    sign_in_as @owner
    patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Profile", postable_uuid: profiles(:carol).uuid }
    assert_response :not_found
  end

  test "update 404s for a group that doesn't belong to the current user" do
    sign_in_as @owner
    patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Group", postable_uuid: groups(:family).uuid }
    assert_response :not_found
  end

  test "update is blocked for a non-member" do
    sign_in_as @outsider
    patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Profile", postable_uuid: profiles(:stray).uuid }
    assert_redirected_to join_chat_server_path(@server)
  end

  test "update responds with a turbo_stream replacing just the picker, not a redirect" do
    # A redirect here would force a full-page Turbo visit, which would wipe
    # out anything the user had already typed into the message textarea —
    # this must stay a targeted replace instead. See also the system test
    # "switching the posting-as profile does not clear an in-progress message".
    sign_in_as @owner
    patch chat_server_channel_default_postable_path(@server, @channel), params: { postable_type: "Profile", postable_uuid: profiles(:bob).uuid },
      as: :turbo_stream
    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_match %r{<turbo-stream action="replace" target="posting-as-picker">}, response.body
    assert_match profiles(:bob).name, response.body
  end
end
