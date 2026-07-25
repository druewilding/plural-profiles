require "application_system_test_case"

# The chat layout's "Sign out" link crosses from chat.* to the main domain
# (SessionsController#destroy only exists there). A plain link relying on
# Turbo's data-turbo-method="delete" silently degrades to a GET for
# cross-origin targets — Turbo only rewrites the method via JS for
# same-origin links — which used to 404/error since SessionsController has
# no #show action. It needs to be a real form submission instead.
class ChatCrossDomainSignOutTest < ApplicationSystemTestCase
  setup do
    @port = Capybara.current_session.server.port
    Capybara.app_host = "http://lvh.me:#{@port}"
    @user = users(:one)
  end

  teardown do
    Capybara.app_host = nil
  end

  test "signing out from the chat subdomain actually signs out instead of erroring" do
    sign_in_via_browser(@user)

    visit "http://chat.lvh.me:#{@port}/"
    assert_text "Your servers"

    click_button "Sign out"

    assert_no_text "Unknown action"
    assert_current_path new_session_path

    visit "http://chat.lvh.me:#{@port}/"
    assert_current_path new_session_path # bounced to sign in — no longer authenticated
  end
end
