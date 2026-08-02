require "application_system_test_case"

# Privacy-critical: the mini-profile popover and the message row must only
# ever surface the resolved chat_* identity (see ChatIdentity), never the
# real full-profile fields underneath it once they diverge — that's the
# entire point of this feature. Every "shows the resolved value" test here
# is paired with an explicit "does not leak the real value" assertion,
# rather than trusting that showing the right thing implies not showing the
# wrong thing too.
class ChatMiniProfileTest < ApplicationSystemTestCase
  setup do
    @port = Capybara.current_session.server.port
    Capybara.app_host = "http://lvh.me:#{@port}"

    @owner = users(:one)
    @viewer = users(:two)

    @server = @owner.owned_chat_servers.create!(name: "Mini Profile Test Server")
    @server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    @server.memberships.create!(user: @viewer, role: "member", default_postable: profiles(:carol))
    @channel = @server.channels.create!(name: "general")
  end

  teardown do
    Capybara.app_host = nil
  end

  def chat_url(path)
    "http://chat.lvh.me:#{@port}#{path}"
  end

  def channel_path
    "/servers/#{@server.uuid}/channels/#{@channel.uuid}"
  end

  def open_popover_for(message_text)
    within(".chat-message", text: message_text) do
      find(".chat-message__name-link").click
    end
  end

  test "clicking a message's name opens a popover showing the resolved chat identity, not the real one" do
    profiles(:alice).update!(
      pronouns: "she/her",
      mini_profile_pronouns_inherited: false, mini_profile_pronouns: "xe/xem",
      mini_profile_tag_line_inherited: false, mini_profile_tag_line: "Chat-only tagline",
      mini_profile_description_inherited: false, mini_profile_description: "Chat-only description"
    )
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "hello there")

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)
    open_popover_for("hello there")

    within(".mini-profile-popover") do
      assert_text "xe/xem"
      assert_text "Chat-only tagline"
      assert_text "Chat-only description"
      assert_no_text "she/her"
    end
  end

  test "clicking a message's avatar also opens the popover" do
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "avatar trigger check")
    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    within(".chat-message", text: "avatar trigger check") do
      find(".chat-message__avatar-trigger").click
    end
    assert_selector ".mini-profile-popover .mini-profile__name", text: "Alice"
  end

  test "the message row itself shows the resolved chat identity, not the real one" do
    profiles(:alice).update!(
      mini_profile_name_inherited: false, mini_profile_name: "Chat Alice",
      pronouns: "she/her", mini_profile_pronouns_inherited: false, mini_profile_pronouns: "xe/xem"
    )
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "identity check")

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    within(".chat-message", text: "identity check") do
      assert_text "Chat Alice"
      assert_text "xe/xem"
      assert_no_text "she/her"
    end
    assert_no_text "Alice", exact: true
  end

  test "a field overridden to blank shows nothing, in the message row or the popover, even though the real profile has a value" do
    profiles(:alice).update!(
      subtitle: "Real subtitle — should never leak",
      mini_profile_subtitle_inherited: false, mini_profile_subtitle: nil
    )
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "blank override check")

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    within("#chat-messages") { assert_no_text "Real subtitle" }
    open_popover_for("blank override check")
    within(".mini-profile-popover") { assert_no_text "Real subtitle" }
  end

  test "the popover never shows an edit link, for the owner or anyone else" do
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "own message")

    sign_in_via_browser(@owner)
    visit chat_url(channel_path)
    open_popover_for("own message")

    within(".mini-profile-popover") { assert_no_text "Edit profile" }
  end

  test "the popover shows no link at all when mini_profile_link_enabled is off, even for the owner" do
    assert_not profiles(:alice).mini_profile_link_enabled?
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "no link check")

    sign_in_via_browser(@owner)
    visit chat_url(channel_path)
    open_popover_for("no link check")

    within(".mini-profile-popover") do
      assert_no_selector ".mini-profile__link"
      assert_no_text "View full profile page"
    end
  end

  test "the popover shows the view-full-page link when enabled, the same for the owner and a non-owner" do
    profiles(:alice).update!(mini_profile_link_enabled: true)
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "link enabled check")

    [ @owner, @viewer ].each do |user|
      sign_in_via_browser(user)
      visit chat_url(channel_path)
      open_popover_for("link enabled check")
      within(".mini-profile-popover") { assert_text "View full profile page" }
      # Signing out via the header form so the next iteration's sign-in starts clean.
      click_button "Sign out"
    end
  end

  test "a message from a deleted postable renders inert text with no popover trigger" do
    message = @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "about to vanish")
    profiles(:alice).destroy

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    within(".chat-message", text: "about to vanish") do
      assert_text "#{message.reload.postable_name} (deleted)"
      assert_no_selector ".chat-message__name-link"
      assert_no_selector ".chat-message__avatar-trigger"
    end
  end

  test "each message from the same postable gets its own independent popover, not a shared/confused one" do
    # mini_profile_frame_id(postable) alone repeats across every message
    # from the same postable — without a per-message discriminator, the
    # page would end up with two <turbo-frame popover> elements sharing an
    # id, which is invalid HTML and risks Turbo updating/matching the wrong
    # one (flagged in code review; verified here rather than only trusted).
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "first message")
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "second message")

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    frame_ids = all(".mini-profile-popover", visible: :all).map { |el| el["id"] }
    assert_equal frame_ids.uniq.length, frame_ids.length, "expected every message's popover frame to have a distinct id, got #{frame_ids}"

    open_popover_for("second message")
    within(".mini-profile-popover") { assert_text "Alice" }

    # The first message's own frame must still be untouched — empty and
    # unopened — not accidentally populated or opened by the second one's fetch.
    within(".chat-message", text: "first message") do
      assert_no_selector ".mini-profile-popover:popover-open"
      assert_selector ".mini-profile-popover:not([src])", visible: :all
    end
  end

  test "an overridden chat avatar shape shows in the popover, but the message row still forces circle" do
    profiles(:alice).avatar.attach(
      io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png"
    )
    profiles(:alice).update!(avatar_shape: "square", mini_profile_avatar_shape: "circle", mini_profile_avatar_inherited: false)
    @channel.messages.create!(user: @owner, postable: profiles(:alice), body: "shape check")

    sign_in_via_browser(@viewer)
    visit chat_url(channel_path)

    within(".chat-message", text: "shape check") do
      assert_selector ".chat-message__avatar .avatar--circle"
      assert_no_selector ".chat-message__avatar .avatar--square"
    end

    open_popover_for("shape check")
    within(".mini-profile-popover") do
      assert_selector ".avatar--circle"
    end
  end
end
