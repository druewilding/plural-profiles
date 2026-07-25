require "test_helper"

class Chat::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "chat.example.com"
    @owner = users(:one)
    @outsider = users(:three)
    @server = @owner.owned_chat_servers.create!(name: "Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
    @channel = @server.channels.create!(name: "general")
  end

  test "create posts a message as the sender's default profile" do
    sign_in_as @owner
    assert_difference "Chat::Message.count", 1 do
      post chat_server_channel_messages_path(@server, @channel), params: { chat_message: { body: "hello there" } }
    end
    assert_redirected_to chat_server_channel_path(@server, @channel)

    message = Chat::Message.order(:created_at).last
    assert_equal "hello there", message.body
    assert_equal profiles(:alice), message.profile
  end

  test "create resolves chat proxy brackets to a different profile" do
    profiles(:bob).update!(chat_bracket_before: "bob:")
    sign_in_as @owner

    post chat_server_channel_messages_path(@server, @channel), params: { chat_message: { body: "bob: hey all" } }

    message = Chat::Message.order(:created_at).last
    assert_equal profiles(:bob), message.profile
    assert_equal "hey all", message.body
  end

  test "create rejects a blank body" do
    sign_in_as @owner
    assert_no_difference "Chat::Message.count" do
      post chat_server_channel_messages_path(@server, @channel), params: { chat_message: { body: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "create is blocked for a non-member" do
    sign_in_as @outsider
    assert_no_difference "Chat::Message.count" do
      post chat_server_channel_messages_path(@server, @channel), params: { chat_message: { body: "hello there" } }
    end
    assert_redirected_to chat_server_path(@server)
  end

  test "index returns messages before the given cursor and flags whether more remain" do
    older = travel_to(3.minutes.ago) { @channel.messages.create!(user: @owner, body: "older") }
    middle = travel_to(2.minutes.ago) { @channel.messages.create!(user: @owner, body: "middle") }
    newest = @channel.messages.create!(user: @owner, body: "newest")

    sign_in_as @owner
    get chat_server_channel_messages_path(@server, @channel,
      before_id: newest.id, before_created_at: newest.created_at.iso8601(6))

    assert_response :success
    assert_match "older", response.body
    assert_match "middle", response.body
    assert_no_match "newest", response.body
  end

  test "index is blocked for a non-member" do
    sign_in_as @outsider
    get chat_server_channel_messages_path(@server, @channel, before_id: 0, before_created_at: Time.current.iso8601(6))
    assert_redirected_to chat_server_path(@server)
  end
end
