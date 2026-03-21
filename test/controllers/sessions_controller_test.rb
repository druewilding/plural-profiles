require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { login: @user.email_address, password: "Plur4l!Pr0files#2026" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { login: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create is rejected for a deactivated account" do
    @user.deactivate!
    post session_path, params: { login: @user.email_address, password: "Plur4l!Pr0files#2026" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "existing session is invalidated when account is deactivated" do
    sign_in_as @user
    @user.deactivate!

    get root_path
    assert_redirected_to new_session_path
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  # -- Login with account name --

  test "create with account name" do
    users(:one).update!(username: "testuser")
    post session_path, params: { login: "testuser", password: "Plur4l!Pr0files#2026" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with account name is case-insensitive" do
    users(:one).update!(username: "testuser")
    post session_path, params: { login: "TestUser", password: "Plur4l!Pr0files#2026" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with account name and wrong password fails" do
    users(:one).update!(username: "testuser")
    post session_path, params: { login: "testuser", password: "wrongpassword" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with non-existent account name fails" do
    post session_path, params: { login: "nobody", password: "Plur4l!Pr0files#2026" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with account name is rejected for a deactivated account" do
    users(:one).update!(username: "testuser")
    users(:one).deactivate!
    post session_path, params: { login: "testuser", password: "Plur4l!Pr0files#2026" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end
end
