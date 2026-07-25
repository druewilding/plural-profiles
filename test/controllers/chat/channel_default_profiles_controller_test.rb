require "test_helper"

class Chat::ChannelDefaultProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @outsider = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
    @channel = @server.channels.create!(name: "general")
  end

  test "update creates a channel-specific default profile for the member" do
    sign_in_as @owner
    assert_difference "Chat::ChannelDefaultProfile.count", 1 do
      patch chat_server_channel_default_profile_path(@server, @channel), params: { profile_uuid: profiles(:bob).uuid }
    end
    assert_redirected_to chat_server_channel_path(@server, @channel)
    assert_equal profiles(:bob), @channel.default_profile_for(@owner)
  end

  test "update overwrites an existing default profile rather than duplicating it" do
    @channel.channel_default_profiles.create!(user: @owner, profile: profiles(:alice))

    sign_in_as @owner
    assert_no_difference "Chat::ChannelDefaultProfile.count" do
      patch chat_server_channel_default_profile_path(@server, @channel), params: { profile_uuid: profiles(:bob).uuid }
    end
    assert_equal profiles(:bob), @channel.default_profile_for(@owner)
  end

  test "update 404s for a profile that doesn't belong to the current user" do
    sign_in_as @owner
    patch chat_server_channel_default_profile_path(@server, @channel), params: { profile_uuid: profiles(:carol).uuid }
    assert_response :not_found
  end

  test "update is blocked for a non-member" do
    sign_in_as @outsider
    patch chat_server_channel_default_profile_path(@server, @channel), params: { profile_uuid: profiles(:stray).uuid }
    assert_redirected_to chat_server_path(@server)
  end
end
