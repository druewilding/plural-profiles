require "application_system_test_case"

# Tests for spoiler reveal/navigation behaviour in the public group explorer.
#
# Decision matrix (spoilers inside links always navigate — no reveal-first step):
#   public group card,  spoiler in link  → loads group panel (single click)
#   public profile card, spoiler in link → loads profile panel (single click)
#   sidebar item (inactive), spoiler    → loads group panel (single click)
#   sidebar item (active),   spoiler    → does nothing (stays on same panel)
#
# Uses fixtures :secret_guild (child group of :alpha_clan with spoiler name) and
# :phantom (direct profile member of :alpha_clan with spoiler name).
class SpoilerPublicExplorerTest < ApplicationSystemTestCase
  setup do
    @user = users(:three)
    sign_in_via_browser
    visit group_path(groups(:alpha_clan).uuid)
    assert_selector ".explorer__content h1", text: "Alpha Clan"
  end

  # ── Group card ────────────────────────────────────────────────────────────

  test "clicking spoiler in a group card loads that group's panel without revealing it" do
    card = find(".profile-card[data-group-uuid='#{groups(:secret_guild).uuid}']")

    card.find(".spoiler").click

    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
    assert_no_selector ".spoiler--revealed"
  end

  # ── Profile card ──────────────────────────────────────────────────────────

  test "clicking spoiler in a profile card loads that profile's panel without revealing it" do
    card = find(".profile-card[data-profile-uuid='#{profiles(:phantom).uuid}']")

    card.find(".spoiler").click

    assert_selector \
      ".tree__item--active[data-group-uuid='#{groups(:alpha_clan).uuid}'][data-profile-uuid='#{profiles(:phantom).uuid}']"
    assert_no_selector ".spoiler--revealed"
  end

  # ── Sidebar tree — inactive item ──────────────────────────────────────────

  test "clicking spoiler in an inactive sidebar tree item loads that group's panel without revealing it" do
    tree_item = find(".tree__item[data-group-uuid='#{groups(:secret_guild).uuid}']")

    tree_item.find(".spoiler").click

    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
    assert_no_selector ".spoiler--revealed"
  end

  # ── Sidebar tree — active item ────────────────────────────────────────────

  test "clicking spoiler in the active sidebar tree item does nothing" do
    # Navigate to secret_guild by clicking its (unrevealed) spoiler in the inactive tree item.
    # The spoiler controller skips spoilers inside links, so the tree controller handles it
    # and makes the item active without revealing the spoiler.
    find(".tree__item[data-group-uuid='#{groups(:secret_guild).uuid}']").find(".spoiler").click
    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
    assert_no_selector ".spoiler--revealed"

    # Click the spoiler again — now the item is active, so the tree controller's active-item
    # guard fires and nothing happens.
    find(".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']").find(".spoiler").click

    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
    assert_no_selector ".spoiler--revealed"
  end
end

# Tests for spoiler reveal/navigation behaviour in the authenticated management pages.
#
# Uses fixture :whisper (profile with spoiler name belonging to user :one).
class SpoilerPrivateCardTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
  end

  test "clicking spoiler in a private profile card navigates to the profile page without revealing it" do
    visit our_profiles_path

    find(".profile-card h3 a .spoiler").click

    assert_current_path our_profile_path(profiles(:whisper))
  end
end
