require "application_system_test_case"

# Tests for sub-group cards on the public group explorer page.
# Uses user :three / alpha_clan which has:
#   alpha_clan
#   ├── Echo Shard  (child group, contains Mirage)
#   ├── Spectrum    (child group)
#   └── Grove       (direct profile)
class PublicGroupExplorerTest < ApplicationSystemTestCase
  setup do
    @user = users(:three)
    sign_in_via_browser
  end

  # ── Sub-group cards in the content panel ─────────────────────────────────

  test "direct child group cards appear in the content panel" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      assert_selector ".profile-card h3", text: "Echo Shard"
      assert_selector ".profile-card h3", text: "Spectrum"
    end
  end

  test "profile cards also appear in the content panel alongside group cards" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      assert_selector ".profile-card h3", text: "Grove"
    end
  end

  test "group cards appear before profile cards in the content panel" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      grids = all(".profile-grid")
      within(grids[0]) { assert_text "Echo Shard" }
      within(grids[1]) { assert_text "Grove" }
    end
  end

  test "grandchild groups do not appear as cards in the root content panel" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      assert_no_selector ".profile-card h3", text: "Prism Circle"
    end
  end

  # ── Clicking a sub-group card loads its content ───────────────────────────

  test "clicking a sub-group card loads that group's content in the panel" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      find(".profile-card", text: "Echo Shard").click
    end

    within(".explorer__content") do
      assert_selector "h1", text: "Echo Shard"
      assert_selector ".profile-card h3", text: "Mirage"
    end
  end

  # ── Clicking a sub-group card highlights the sidebar ─────────────────────

  test "clicking a sub-group card highlights the matching sidebar tree item" do
    visit group_path(groups(:alpha_clan).uuid)

    within(".explorer__content") do
      find(".profile-card", text: "Echo Shard").click
    end

    within(".explorer__sidebar") do
      assert_selector ".tree__item--active[data-group-uuid='#{groups(:echo_shard).uuid}']"
    end
  end

  test "clicking a sub-group card clears the previous active state" do
    visit group_path(groups(:alpha_clan).uuid)

    # Click Echo Shard first, then Spectrum — only Spectrum should be active
    within(".explorer__content") do
      find(".profile-card", text: "Echo Shard").click
    end

    within(".explorer__sidebar") do
      assert_selector ".tree__item--active[data-group-uuid='#{groups(:echo_shard).uuid}']"
    end

    within(".explorer__sidebar") do
      find(".tree__item[data-group-uuid='#{groups(:spectrum).uuid}']").click
    end

    within(".explorer__sidebar") do
      assert_selector ".tree__item--active[data-group-uuid='#{groups(:spectrum).uuid}']"
      assert_no_selector ".tree__item--active[data-group-uuid='#{groups(:echo_shard).uuid}']"
    end
  end
end
