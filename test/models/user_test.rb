require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires email_address" do
    user = User.new(password: "N3wUs3r!S1gnup#2026", password_confirmation: "N3wUs3r!S1gnup#2026")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email_address" do
    user = User.new(
      email_address: users(:one).email_address,
      password: "N3wUs3r!S1gnup#2026",
      password_confirmation: "N3wUs3r!S1gnup#2026"
    )
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires valid email format" do
    user = User.new(email_address: "not-an-email", password: "N3wUs3r!S1gnup#2026", password_confirmation: "N3wUs3r!S1gnup#2026")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "requires password with minimum length" do
    user = User.new(email_address: "new@example.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "has many profiles" do
    user = users(:one)
    assert_includes user.profiles, profiles(:alice)
    assert_includes user.profiles, profiles(:bob)
  end

  test "has many groups" do
    user = users(:one)
    assert_includes user.groups, groups(:friends)
  end

  test "destroying user destroys associated profiles" do
    user = users(:one)
    profile_count = user.profiles.count
    assert_difference("Profile.count", -profile_count) { user.destroy }
  end

  test "destroying user destroys associated groups" do
    user = users(:one)
    group_count = user.groups.count
    assert_difference("Group.count", -group_count) { user.destroy }
  end

  # -- Deactivation --

  test "deactivated? is false for a normal user" do
    assert_not users(:one).deactivated?
  end

  test "deactivated? is true when deactivated_at is set" do
    user = users(:one)
    user.update_column(:deactivated_at, Time.current)
    assert user.deactivated?
  end

  test "deactivate! sets deactivated_at" do
    user = users(:one)
    assert_nil user.deactivated_at
    user.deactivate!
    assert_not_nil user.reload.deactivated_at
  end

  test "deactivate! destroys all sessions" do
    user = users(:one)
    user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
    user.sessions.create!(user_agent: "test2", ip_address: "127.0.0.2")
    assert user.sessions.any?
    user.deactivate!
    assert user.sessions.reload.empty?
  end
end
