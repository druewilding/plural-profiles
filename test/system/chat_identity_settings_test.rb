require "application_system_test_case"

# The settings page is the entire privacy control surface for this feature —
# these tests drive the real Stimulus toggle/live-preview/save flow in an
# actual browser, rather than trusting that the controller-level tests
# (Our::ChatIdentitiesControllerTest) imply the JS wiring in front of them
# behaves the same way.
class ChatIdentitySettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @profile = profiles(:alice)
    sign_in_via_browser(@user)
  end

  def toggle_field(label, to:)
    within(".chat-identity-field", text: label) do
      find(".chat-identity-toggle__option", text: to).click
    end
  end

  test "toggling a field to 'Set for chat' reveals its input and updates the live preview, without touching the main profile" do
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    within(".chat-identity-field", text: "Subtitle") do
      assert_no_selector "input[name='chat_identity[mini_profile_subtitle]']", visible: true
    end

    toggle_field("Subtitle", to: "Set for chat")
    fill_in "chat_identity[mini_profile_subtitle]", with: "Chat-only subtitle"

    within("#chat-identity-preview-panel") { assert_text "Chat-only subtitle" }

    assert_nil @profile.reload.subtitle
    assert @profile.mini_profile_subtitle_inherited?
  end

  test "saving persists the change" do
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    toggle_field("Subtitle", to: "Set for chat")
    fill_in "chat_identity[mini_profile_subtitle]", with: "Saved chat subtitle"
    click_button "Save chat settings"

    assert_text "Chat settings updated."
    @profile.reload
    assert_not @profile.mini_profile_subtitle_inherited?
    assert_equal "Saved chat subtitle", @profile.mini_profile_subtitle
    assert_nil @profile.subtitle
  end

  test "toggling back to 'Use main' hides the override input and the live preview reverts to the main value" do
    @profile.update!(subtitle: "Real subtitle", mini_profile_subtitle_inherited: false, mini_profile_subtitle: "Old chat subtitle")
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    within("#chat-identity-preview-panel") { assert_text "Old chat subtitle" }

    toggle_field("Subtitle", to: "Use main")

    within("#chat-identity-preview-panel") do
      assert_text "Real subtitle"
      assert_no_text "Old chat subtitle"
    end
  end

  test "the live preview never shows a field the checkbox hasn't enabled" do
    assert_not @profile.mini_profile_link_enabled?
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    within("#chat-identity-preview-panel") { assert_no_text "View full profile page" }

    check "chat_identity[mini_profile_link_enabled]"
    within("#chat-identity-preview-panel") { assert_text "View full profile page" }
  end

  # Deliberately doesn't click "Save chat settings" after attaching a file —
  # submitting this form via Turbo with a real file attached hits a
  # pre-existing environment limitation, unrelated to this feature: the exact
  # same "Failed to fetch" reproduces on the plain, untouched main-profile
  # avatar upload form (Our::ProfilesController) too. avatar_editor_test.rb
  # avoids this same combination for the same reason — it only exercises the
  # dialog's own in-page preview, never a real post-attach form submit.
  # Actual persistence of mini_profile_avatar is covered without a real
  # browser file input in Our::ChatIdentitiesControllerTest instead.
  test "picking a chat avatar previews immediately in the live message/popover preview, independently of the main avatar" do
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    toggle_field("Chat avatar", to: "Set for chat")
    click_button "Set chat avatar"
    attach_file "chat_identity[mini_profile_avatar]", file_fixture("avatar.png").to_path
    find(".avatar-shape-picker__option", text: "Circle").click
    click_button "Done"

    within("#chat-identity-preview-panel .chat-message__avatar") { assert_selector "img.avatar--circle" }
    within("#chat-identity-preview-panel .mini-profile__header") { assert_selector "img.avatar--circle" }
  end

  # Regression: shape and image are independent overrides (see
  # ChatIdentity) — removing the picked chat avatar image should fall back
  # to the main avatar's image, but must not also discard a shape picked in
  # the same dialog session. The live-preview JS previously read {src,
  # shape} off the avatar-editor:changed event and discarded shape whenever
  # src was null (an explicit removal), silently reverting the popover
  # preview to the main avatar's own shape instead.
  test "removing a picked chat avatar image keeps the shape picked alongside it, in the live preview" do
    @profile.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "main.png", content_type: "image/png")
    @profile.mini_profile_avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "chat.png", content_type: "image/png")
    @profile.update!(avatar_shape: "square", mini_profile_avatar_shape: "rounded", mini_profile_avatar_inherited: false)

    visit edit_our_chat_identity_path("Profile", @profile.uuid)
    click_button "Set chat avatar"
    find(".avatar-shape-picker__option", text: "Circle").click
    check "Remove avatar"
    click_button "Done"

    within("#chat-identity-preview-panel .mini-profile__header") do
      assert_selector ".avatar--circle"
      assert_no_selector ".avatar--square"
    end
  end

  test "a blank required name shows a validation error and does not save" do
    visit edit_our_chat_identity_path("Profile", @profile.uuid)

    toggle_field("Name", to: "Set for chat")
    fill_in "chat_identity[mini_profile_name]", with: ""
    click_button "Save chat settings"

    assert_text "can't be blank when not inheriting the main name"
    assert @profile.reload.mini_profile_name_inherited?
  end
end
