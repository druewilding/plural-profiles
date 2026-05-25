require "application_system_test_case"

class AvatarEditorTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @profile = profiles(:alice)
    sign_in_via_browser
  end

  teardown do
    @profile.avatar.purge if @profile.avatar.attached?
  end

  test "avatar editor dialog is closed on page load" do
    visit edit_our_profile_path(@profile)
    assert_no_selector "dialog.avatar-editor-dialog[open]"
  end

  test "clicking Add avatar opens the dialog" do
    visit edit_our_profile_path(@profile)
    click_button "Add avatar"
    assert_selector "dialog.avatar-editor-dialog[open]"
  end

  test "clicking Done closes the dialog and shows selected image in main preview" do
    visit edit_our_profile_path(@profile)
    click_button "Add avatar"

    attach_file "profile[avatar]", file_fixture("avatar.png").to_path

    click_button "Done"

    assert_no_selector "dialog.avatar-editor-dialog[open]"
    assert_selector "[data-avatar-editor-target='mainPreview']", visible: true
  end

  test "clicking Cancel closes the dialog without updating the main preview" do
    visit edit_our_profile_path(@profile)
    click_button "Add avatar"

    attach_file "profile[avatar]", file_fixture("avatar.png").to_path
    assert_selector "[data-avatar-editor-target='dialogPreview']", visible: true

    click_button "Cancel"

    assert_no_selector "dialog.avatar-editor-dialog[open]"
    assert_no_selector "[data-avatar-editor-target='mainPreview']", visible: true
  end

  test "selecting circle shape applies circle style to dialog preview" do
    visit edit_our_profile_path(@profile)
    click_button "Add avatar"

    attach_file "profile[avatar]", file_fixture("avatar.png").to_path
    find(".avatar-shape-picker__option", text: "Circle").click

    assert_selector "[data-avatar-editor-target='dialogPreview'].avatar--circle", visible: true
  end
end
