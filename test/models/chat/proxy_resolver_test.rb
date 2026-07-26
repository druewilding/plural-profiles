require "test_helper"

class Chat::ProxyResolverTest < ActiveSupport::TestCase
  test "matches a before-only prefix exactly" do
    profile = users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    match = Chat::ProxyResolver.resolve(users(:one), "guy: hello there")
    assert_equal profile, match[:postable]
    assert_equal "hello there", match[:content]
  end

  test "does not match when the case differs" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "Guy: hello there")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "GUY: hello there")
  end

  test "brackets differing only by case can identify two different profiles" do
    lower = users(:one).profiles.create!(name: "Lowercase Guy", chat_bracket_before: "guy:")
    upper = users(:one).profiles.create!(name: "Uppercase Guy", chat_bracket_before: "GUY:")

    lower_match = Chat::ProxyResolver.resolve(users(:one), "guy: hi")
    upper_match = Chat::ProxyResolver.resolve(users(:one), "GUY: hi")

    assert_equal lower, lower_match[:postable]
    assert_equal upper, upper_match[:postable]
  end

  test "matches a before/after wrap" do
    profile = users(:one).profiles.create!(name: "Brace", chat_bracket_before: "{", chat_bracket_after: "}")
    match = Chat::ProxyResolver.resolve(users(:one), "{hello there}")
    assert_equal profile, match[:postable]
    assert_equal "hello there", match[:content]
  end

  test "matches an after-only suffix" do
    profile = users(:one).profiles.create!(name: "Suffix", chat_bracket_after: "-g")
    match = Chat::ProxyResolver.resolve(users(:one), "hello there-g")
    assert_equal profile, match[:postable]
    assert_equal "hello there", match[:content]
  end

  test "returns nil when nothing matches" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "just a normal message")
  end

  test "returns nil for a blank body" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "")
  end

  test "returns nil when the extracted content would be blank" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "guy:   ")
  end

  test "never matches another user's profiles" do
    users(:two).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "guy: hello")
  end

  test "picks the more specific (longer) brackets when more than one profile matches" do
    short_match = users(:one).profiles.create!(name: "Short", chat_bracket_before: "g")
    long_match = users(:one).profiles.create!(name: "Long", chat_bracket_before: "g:")
    match = Chat::ProxyResolver.resolve(users(:one), "g: hello")
    assert_equal long_match, match[:postable]
    assert_not_equal short_match, match[:postable]
    assert_equal "hello", match[:content]
  end

  test "matches a group's brackets" do
    group = users(:one).groups.create!(name: "Friends Group", chat_bracket_before: "friends:")
    match = Chat::ProxyResolver.resolve(users(:one), "friends: hello there")
    assert_equal group, match[:postable]
    assert_equal "hello there", match[:content]
  end

  test "never matches another user's groups" do
    users(:two).groups.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Chat::ProxyResolver.resolve(users(:one), "guy: hello")
  end

  test "picks the more specific brackets across a profile and a group" do
    profile = users(:one).profiles.create!(name: "Short", chat_bracket_before: "g")
    group = users(:one).groups.create!(name: "Long", chat_bracket_before: "g:")

    match = Chat::ProxyResolver.resolve(users(:one), "g: hello")

    assert_equal group, match[:postable]
    assert_not_equal profile, match[:postable]
    assert_equal "hello", match[:content]
  end
end
