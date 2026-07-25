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

  test "create a server, add a channel, invite a friend, and they join and post" do
    sign_in_via_browser(@owner)
    visit chat_url
    click_link "New server"

    fill_in "Name", with: "Book Club"
    select profiles(:alice).name, from: "chat_server[default_profile_id]"
    click_button "Create server"

    assert_text "Server created."
    assert_text "Book Club"
    assert_text "No channels yet."

    click_link "+ Add channel"
    fill_in "Name", with: "general"
    click_button "Create channel"

    assert_text "Channel created."
    assert_text "No messages yet. Say hello!"

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
    select profiles(:carol).name, from: "default_profile_id"
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
    server.memberships.create!(user: @owner, role: "owner", default_profile: profiles(:alice))
    invite = server.server_invites.create!(created_by: @owner)

    other_user = users(:three)
    sign_in_via_browser(other_user)
    visit chat_url("/invite/#{invite.token}")
    click_link "Accept invite"
    select profiles(:stray).name, from: "default_profile_id"
    click_button "Join server"
    assert_text "Joined Solo Server."

    click_button "Sign out"

    sign_in_via_browser(users(:four))
    visit chat_url("/invite/#{invite.token}")

    assert_text "This invite link is no longer valid."
  end
end
