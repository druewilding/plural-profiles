require "test_helper"

# The chat. subdomain bounces sign-in to the main domain (see
# SessionsController#redirect_to_main_domain), then is supposed to return the
# user to the chat page they originally wanted. That round trip depends on
# two things staying in sync: the framework session cookie surviving the
# domain hop (config/initializers/session_store.rb), and the final redirect
# in SessionsController#create being allowed to cross hosts.
class ChatAuthenticationRedirectTest < ActionDispatch::IntegrationTest
  test "signing in on the main domain returns you to the chat page you were trying to reach" do
    user = users(:one)
    server = user.owned_chat_servers.create!(name: "Test Server")
    server.memberships.create!(user: user, role: "owner", default_profile: profiles(:alice))

    host! "chat.example.com"
    original_url = "http://chat.example.com#{chat_server_path(server)}"

    get original_url
    assert_redirected_to "http://chat.example.com/session/new"

    follow_redirect!
    assert_redirected_to "http://example.com/session/new"

    follow_redirect!
    assert_response :success
    assert_equal "example.com", request.host

    post "http://example.com/session", params: { login: user.email_address, password: "Plur4l!Pr0files#2026" }

    assert_redirected_to original_url
  end
end
