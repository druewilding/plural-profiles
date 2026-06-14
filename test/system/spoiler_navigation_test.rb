require "application_system_test_case"

# Tests for spoiler reveal/navigation behaviour in the public group explorer.
#
# Decision matrix:
#   public group card,  unrevealed  → reveals spoiler, panel unchanged
#   public group card,  revealed    → loads group panel (sidebar item becomes active)
#   public profile card, unrevealed → reveals spoiler, panel unchanged
#   public profile card, revealed   → loads profile panel (sidebar item becomes active)
#   sidebar item (inactive), unrevealed → reveals spoiler, panel unchanged
#   sidebar item (inactive), revealed   → loads group panel
#   sidebar item (active),   revealed   → hides spoiler, item stays active
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

  test "clicking unrevealed spoiler in a group card reveals it without navigating" do
    card = find(".profile-card[data-group-uuid='#{groups(:secret_guild).uuid}']")

    assert_no_selector ".spoiler--revealed"
    card.find(".spoiler").click

    assert_selector ".spoiler--revealed"
    assert_selector ".explorer__content h1", text: "Alpha Clan"
  end

  test "clicking revealed spoiler in a group card loads that group's panel" do
    card = find(".profile-card[data-group-uuid='#{groups(:secret_guild).uuid}']")
    card.find(".spoiler").click  # reveal
    card.find(".spoiler").click  # navigate

    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
  end

  # ── Profile card ──────────────────────────────────────────────────────────

  test "clicking unrevealed spoiler in a profile card reveals it without navigating" do
    card = find(".profile-card[data-profile-uuid='#{profiles(:phantom).uuid}']")

    assert_no_selector ".spoiler--revealed"
    card.find(".spoiler").click

    assert_selector ".spoiler--revealed"
    assert_selector ".explorer__content h1", text: "Alpha Clan"
  end

  test "clicking revealed spoiler in a profile card loads that profile's panel" do
    card = find(".profile-card[data-profile-uuid='#{profiles(:phantom).uuid}']")
    card.find(".spoiler").click  # reveal
    card.find(".spoiler").click  # navigate

    assert_selector \
      ".tree__item--active[data-group-uuid='#{groups(:alpha_clan).uuid}'][data-profile-uuid='#{profiles(:phantom).uuid}']"
  end

  # ── Sidebar tree — inactive item ──────────────────────────────────────────

  test "clicking unrevealed spoiler in an inactive sidebar item reveals it without loading the panel" do
    tree_item = find(".tree__item[data-group-uuid='#{groups(:secret_guild).uuid}']")

    assert_no_selector ".spoiler--revealed"
    tree_item.find(".spoiler").click

    assert_selector ".spoiler--revealed"
    assert_selector ".explorer__content h1", text: "Alpha Clan"
  end

  test "clicking revealed spoiler in an inactive sidebar item loads that group's panel" do
    tree_item = find(".tree__item[data-group-uuid='#{groups(:secret_guild).uuid}']")
    tree_item.find(".spoiler").click  # reveal
    tree_item.find(".spoiler").click  # navigate

    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
  end

  # ── Sidebar tree — active item ────────────────────────────────────────────

  test "clicking revealed spoiler in the active sidebar item hides it without reloading" do
    # Navigate to secret_guild by clicking its avatar placeholder — this triggers the
    # tree controller without touching the spoiler, so the spoiler stays unrevealed.
    within(".explorer__content") do
      find(".profile-card[data-group-uuid='#{groups(:secret_guild).uuid}'] .avatar--placeholder").click
    end
    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"

    # Now reveal the spoiler in the active sidebar item
    tree_item = find(".tree__item[data-group-uuid='#{groups(:secret_guild).uuid}']")
    assert_no_selector ".spoiler--revealed"
    tree_item.find(".spoiler").click  # reveal
    assert_selector ".spoiler--revealed"

    # Click the revealed spoiler on the active item — should re-hide, not navigate
    tree_item.find(".spoiler").click  # re-hide
    assert_no_selector ".spoiler--revealed"
    assert_selector ".tree__item--active[data-group-uuid='#{groups(:secret_guild).uuid}']"
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

  test "clicking unrevealed spoiler in a private profile card name reveals it without navigating" do
    visit our_profiles_path

    spoiler = find(".profile-card h3 a .spoiler")
    assert_no_selector ".spoiler--revealed"
    spoiler.click

    assert_selector ".spoiler--revealed"
    assert_current_path our_profiles_path
  end

  test "clicking revealed spoiler in a private profile card name navigates to the profile page" do
    visit our_profiles_path

    spoiler = find(".profile-card h3 a .spoiler")
    spoiler.click  # reveal
    assert_selector ".spoiler--revealed"
    spoiler.click  # navigate

    assert_current_path our_profile_path(profiles(:whisper))
  end
end
