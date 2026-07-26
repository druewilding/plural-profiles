require "application_system_test_case"

# Covers interactions that only show up once two members are involved: a
# live Action Cable broadcast landing in someone else's already-open browser
# tab, and the unread-dot bookkeeping that runs alongside it.
class ChatMessagingTest < ApplicationSystemTestCase
  setup do
    @port = Capybara.current_session.server.port
    Capybara.app_host = "http://lvh.me:#{@port}"

    @owner = users(:one)
    @member = users(:two)

    @server = @owner.owned_chat_servers.create!(name: "Live Server")
    @server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
    @server.memberships.create!(user: @member, role: "member", default_profile: profiles(:carol))
    @channel = @server.channels.create!(name: "general")
    @other_channel = @server.channels.create!(name: "off-topic")
  end

  teardown do
    Capybara.app_host = nil
  end

  def chat_url(path)
    "http://chat.lvh.me:#{@port}#{path}"
  end

  def channel_path(channel = @channel)
    "/servers/#{@server.uuid}/channels/#{channel.uuid}"
  end

  def send_message(text)
    fill_in placeholder: "Message ##{@channel.name} (Enter to send, Shift+Enter for a new line)", with: text
    find("textarea").native.send_keys(:enter)
  end

  test "a message posted by one member appears live for another member already viewing the channel" do
    using_session(:owner) do
      sign_in_via_browser(@owner)
      visit chat_url(channel_path)
      assert_text "No messages yet. Say hello!"
    end

    using_session(:member) do
      sign_in_via_browser(@member)
      visit chat_url(channel_path)
      send_message("Hi from Carol!")
      assert_text "Hi from Carol!"
    end

    using_session(:owner) do
      # No reload here — this only appears if the turbo_stream_from broadcast
      # (Chat::Message#broadcast_append_to) reached this open tab live.
      assert_text "Hi from Carol!"
      assert_text "Carol"
    end
  end

  test "switching the posting-as profile changes whose name is attached to new messages" do
    sign_in_via_browser(@owner)
    visit chat_url(channel_path)

    assert_text "Posting as"
    assert_text profiles(:alice).name

    within(".composer-posting-as") do
      find(".profile-picker__trigger").click
      click_link profiles(:bob).name
    end

    # The profile switch link is a Turbo PATCH that redirects back to this
    # same channel page — wait for that round-trip to settle (fresh composer,
    # fresh textarea) before typing, or send_keys can hit a stale element.
    assert_selector ".profile-picker__trigger", text: profiles(:bob).name

    send_message("Switched over to Bob")

    within("#chat-messages") do
      assert_text "Switched over to Bob"
      assert_text profiles(:bob).name
      assert_no_text profiles(:alice).name
    end
  end

  test "typing a profile's chat proxy brackets posts as that profile instead of the default" do
    profiles(:bob).update!(chat_bracket_before: "bob:")

    sign_in_via_browser(@owner)
    visit chat_url(channel_path)

    send_message("bob: borrowed the mic")

    within("#chat-messages") do
      assert_text "borrowed the mic"
      assert_text profiles(:bob).name
      assert_no_text "bob:" # the prefix itself is stripped from the stored body
    end
  end

  test "typing a profile's chat proxy brackets in a different case does not match — falls back to the default" do
    profiles(:bob).update!(chat_bracket_before: "bob:")

    sign_in_via_browser(@owner)
    visit chat_url(channel_path)

    fill_in placeholder: "Message ##{@channel.name} (Enter to send, Shift+Enter for a new line)", with: "BOB: shouting today"

    # The live "Posting as" preview (composer_controller.js#matchProxy) should
    # NOT have switched — case-sensitive brackets can identify two different
    # profiles ("bob:" vs "BOB:"), so a case mismatch is simply no match.
    assert_selector ".profile-picker__trigger", text: profiles(:alice).name
    assert_no_selector ".profile-picker__trigger", text: profiles(:bob).name

    find("textarea").native.send_keys(:enter)

    within("#chat-messages") do
      assert_text "BOB: shouting today"
      assert_text profiles(:alice).name
      assert_no_text profiles(:bob).name
    end
  end

  test "an unread dot lights up a channel and server that a message arrives in, and clears on read" do
    using_session(:owner) do
      sign_in_via_browser(@owner)
      # Sitting on the server page (not the channel), so the new message
      # shouldn't be marked read just from this.
      visit chat_url("/servers/#{@server.uuid}")
      within(".channel-pane") { assert_no_selector ".unread-dot" }
    end

    using_session(:member) do
      sign_in_via_browser(@member)
      visit chat_url(channel_path)
      send_message("Anybody around?")
    end

    using_session(:owner) do
      within(".channel-pane") { assert_selector ".unread-dot" }
      within(".server-rail") { assert_selector ".unread-dot--rail" }

      within(".channel-pane") { click_link "general" }
      assert_text "Anybody around?"

      # mark_read fires client-side once the channel page has mounted
      # (see channel_read_controller.js) rather than on the GET itself.
      within(".channel-pane") { assert_no_selector ".unread-dot" }
      within(".server-rail") { assert_no_selector ".unread-dot--rail" }
    end
  end
end
