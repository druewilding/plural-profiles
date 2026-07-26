require "test_helper"

class Chat::ChannelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @member = users(:two)
    @outsider = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @member, role: "member", default_postable: profiles(:carol))
    @channel = @server.channels.create!(name: "general")
  end

  test "show renders the channel for a member" do
    @channel.messages.create!(user: @owner, body: "hello there")
    sign_in_as @member
    get chat_server_channel_path(@server, @channel)
    assert_response :success
    assert_match "hello there", response.body
  end

  test "message author links go to the viewer's own profile page, but the public page for others" do
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "from the owner")
    @channel.messages.create!(user: @member, postable: profiles(:carol), body: "from the member")

    sign_in_as @owner
    get chat_server_channel_path(@server, @channel)
    assert_response :success

    assert_match our_profile_path(profiles(:alice)), response.body
    assert_match profile_path(profiles(:carol)), response.body
    assert_no_match our_profile_path(profiles(:carol)), response.body
  end

  test "show is blocked for a non-member" do
    sign_in_as @outsider
    get chat_server_channel_path(@server, @channel)
    assert_redirected_to join_chat_server_path(@server)
    assert_equal "Join this server first.", flash[:alert]
  end

  test "mark_read records a channel read and responds with no content" do
    sign_in_as @member
    assert_difference "Chat::ChannelRead.count", 1 do
      patch mark_read_chat_server_channel_path(@server, @channel)
    end
    assert_response :no_content
    assert Chat::ChannelRead.find_by(user: @member, channel: @channel).present?
  end

  test "mark_read is blocked for a non-member" do
    sign_in_as @outsider
    patch mark_read_chat_server_channel_path(@server, @channel)
    assert_redirected_to join_chat_server_path(@server)
  end

  test "new is only accessible to the server owner" do
    sign_in_as @member
    get new_chat_server_channel_path(@server)
    assert_redirected_to chat_server_path(@server)
    assert_equal "Only the server owner can do that.", flash[:alert]
  end

  test "create adds a channel when the owner submits a valid name" do
    sign_in_as @owner
    assert_difference "Chat::Channel.count", 1 do
      post chat_server_channels_path(@server), params: { chat_channel: { name: "off-topic" } }
    end
    assert_redirected_to chat_server_channel_path(@server, Chat::Channel.order(:created_at).last)
  end

  test "create is blocked for a non-owner member" do
    sign_in_as @member
    assert_no_difference "Chat::Channel.count" do
      post chat_server_channels_path(@server), params: { chat_channel: { name: "off-topic" } }
    end
    assert_redirected_to chat_server_path(@server)
  end

  test "create rejects a duplicate channel name within the same server" do
    sign_in_as @owner
    assert_no_difference "Chat::Channel.count" do
      post chat_server_channels_path(@server), params: { chat_channel: { name: "general" } }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects a theme the owner doesn't have access to" do
    sign_in_as @owner
    assert_no_difference "Chat::Channel.count" do
      post chat_server_channels_path(@server), params: { chat_channel: { name: "off-topic", theme_id: themes(:other_user_theme).id } }
    end
    assert_response :unprocessable_entity
    assert_match "is not available", response.body
  end

  test "update lets the owner rename the channel" do
    sign_in_as @owner
    patch chat_server_channel_path(@server, @channel), params: { chat_channel: { name: "renamed" } }
    assert_redirected_to chat_server_channel_path(@server, @channel.reload)
    assert_equal "renamed", @channel.name
  end

  test "update is blocked for a non-owner" do
    sign_in_as @member
    patch chat_server_channel_path(@server, @channel), params: { chat_channel: { name: "hijacked" } }
    assert_redirected_to chat_server_path(@server)
    assert_not_equal "hijacked", @channel.reload.name
  end
end
