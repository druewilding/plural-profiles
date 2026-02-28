require "test_helper"

class Our::InviteCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "create generates an invite code" do
    assert_difference("InviteCode.count", 1) do
      post our_invite_codes_path
    end
    assert_redirected_to our_account_path
    follow_redirect!
    assert_match "Invite code created", response.body
  end

  test "create refuses when at maximum unused codes" do
    # The user already has 1 unused code from fixtures, create more to hit the limit
    (InviteCode::MAX_UNUSED_PER_USER - @user.invite_codes.unused.count).times do
      @user.invite_codes.create!
    end

    assert_no_difference("InviteCode.count") do
      post our_invite_codes_path
    end
    assert_redirected_to our_account_path
    follow_redirect!
    assert_match "already have #{InviteCode::MAX_UNUSED_PER_USER}", response.body
  end

  test "create requires authentication" do
    sign_out
    post our_invite_codes_path
    assert_redirected_to new_session_path
  end

  # -- destroy --

  test "destroy deletes an unused invite code" do
    invite = invite_codes(:available)

    assert_difference("InviteCode.count", -1) do
      delete our_invite_code_path(invite)
    end
    assert_redirected_to our_account_path
    follow_redirect!
    assert_match "Invite code deleted", response.body
  end

  test "destroy cannot delete another user's invite code" do
    other_invite = invite_codes(:available)
    sign_out
    sign_in_as users(:two)

    assert_no_difference("InviteCode.count") do
      delete our_invite_code_path(other_invite)
    end
    assert_redirected_to our_account_path
    follow_redirect!
    assert_match "not found or already used", response.body
  end

  test "destroy cannot delete a used invite code" do
    used_invite = invite_codes(:used)

    assert_no_difference("InviteCode.count") do
      delete our_invite_code_path(used_invite)
    end
    assert_redirected_to our_account_path
    follow_redirect!
    assert_match "not found or already used", response.body
  end

  test "destroy requires authentication" do
    sign_out
    delete our_invite_code_path(invite_codes(:available))
    assert_redirected_to new_session_path
  end
end
