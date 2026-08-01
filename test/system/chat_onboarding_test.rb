require "application_system_test_case"

# Chat lives on its own subdomain and shares the session cookie across it
# (see Authentication#start_new_session_for, domain: :all). System tests need
# to sign in with Capybara.app_host already pointed at lvh.me so the cookie is
# set on a domain the chat.lvh.me subdomain can also read.
class ChatOnboardingTest < ApplicationSystemTestCase
  setup do
    @port = Capybara.current_session.server.port
    Capybara.app_host = "http://lvh.me:#{@port}"
    @owner = users(:one)
    @friend = users(:two)
  end

  teardown do
    Capybara.app_host = nil
  end

  def chat_url(path = "/")
    "http://chat.lvh.me:#{@port}#{path}"
  end

  # The "Post as" field is a searchable profile/group picker (same component
  # as the composer's identity switcher), not a plain <select> — open it,
  # filter down to the target profile or group, and click it.
  def choose_post_as_profile(name)
    find(".profile-picker__trigger").click
    fill_in placeholder: "Find a profile or group…", with: name
    click_button name
  end

  test "create a server, add a channel, invite a friend, and they join and post" do
    sign_in_via_browser(@owner)
    visit chat_url
    click_link "New server"

    fill_in "Name", with: "Book Club"
    fill_in "Subtitle", with: "For readers of all kinds"
    fill_in "Description", with: "A cozy corner to talk about what we're reading"
    choose_post_as_profile(profiles(:alice).name)
    click_button "Create server"

    assert_text "Server created."
    assert_text "Book Club"
    assert_text "For readers of all kinds"
    assert_text "A cozy corner to talk about what we're reading"
    assert_text "No channels yet."

    click_link "+ Add channel"
    fill_in "Name", with: "general"
    fill_in "Subtitle", with: "Say hello here"
    fill_in "Description", with: "The main hangout"
    click_button "Create channel"

    assert_text "Channel created."
    assert_text "Say hello here"
    assert_text "The main hangout"
    assert_text "No messages yet. Say hello!"

    # Posts as the owner, using the default postable chosen on the server
    # creation form — regression coverage for a bug where that form's picker
    # (nested under "chat_server[...]") silently failed to set
    # default_postable_type/_id, leaving the owner unable to post at all.
    fill_in placeholder: "Message #general (Enter to send, Shift+Enter for a new line)", with: "Welcome to the club!"
    find("textarea").native.send_keys(:enter)
    assert_text "Welcome to the club!"
    assert_text profiles(:alice).name

    within(".channel-pane") { click_link "Book Club" } # back to the server page, which has the invite link
    click_link "Invite people"
    invite_url = find("#invite-share-url").value
    assert_match %r{\Ahttp://chat\.lvh\.me:#{@port}/invite/}, invite_url

    click_button "Sign out"

    sign_in_via_browser(@friend)
    visit invite_url

    assert_text "Join Book Club?"
    click_link "Accept invite"

    assert_text "Join Book Club"
    choose_post_as_profile(profiles(:carol).name)
    click_button "Join server"

    assert_text "Joined Book Club."

    click_link "general"
    fill_in placeholder: "Message #general (Enter to send, Shift+Enter for a new line)", with: "Hello, book club!"
    find("textarea").native.send_keys(:enter)

    assert_text "Hello, book club!"
    assert_text profiles(:carol).name
  end

  test "an invite link cannot be used twice" do
    server = @owner.owned_chat_servers.create!(name: "Solo Server")
    server.memberships.create!(user: @owner, role: "owner", default_postable: profiles(:alice))
    invite = server.server_invites.create!(created_by: @owner)

    other_user = users(:three)
    sign_in_via_browser(other_user)
    visit chat_url("/invite/#{invite.token}")
    click_link "Accept invite"
    choose_post_as_profile(profiles(:stray).name)
    click_button "Join server"
    assert_text "Joined Solo Server."

    click_button "Sign out"

    sign_in_via_browser(users(:four))
    visit chat_url("/invite/#{invite.token}")

    assert_text "This invite link is no longer valid."
  end
end
