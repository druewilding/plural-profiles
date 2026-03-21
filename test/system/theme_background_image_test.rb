require "application_system_test_case"

class ThemeBackgroundImageTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @theme = themes(:sunset)
    sign_in_via_browser
  end

  teardown do
    @theme.background_image.purge if @theme.background_image.attached?
  end

  # -- Uploading a background image --

  test "uploading a background image updates the preview immediately" do
    visit edit_our_theme_path(@theme)

    find("summary", text: "Background image").click
    attach_file "theme[background_image]", file_fixture("avatar.png").to_path

    # Stimulus applies the image to the preview element
    preview_style = find(".theme-preview")[:style]
    assert_match(/background-image:\s*url\(/, preview_style)
  end

  test "background image thumbnail and remove checkbox appear when an image is attached" do
    @theme.background_image.attach(
      io: file_fixture("avatar.png").open,
      filename: "avatar.png",
      content_type: "image/png"
    )

    visit edit_our_theme_path(@theme)
    find("summary", text: "Background image").click

    assert_css "img.theme-bg-preview"
    assert_text "Remove background image"
  end

  # -- Removing a background image --

  test "can remove a background image via the remove checkbox" do
    @theme.background_image.attach(
      io: file_fixture("avatar.png").open,
      filename: "avatar.png",
      content_type: "image/png"
    )

    visit edit_our_theme_path(@theme)
    find("summary", text: "Background image").click

    assert_css "img.theme-bg-preview"

    check "Remove background image"
    click_button "Save theme"

    assert_text "Theme saved."

    visit edit_our_theme_path(@theme)
    find("summary", text: "Background image").click

    assert_no_css "img.theme-bg-preview"
    assert_no_text "Remove background image"
  end

  # -- Background image in body style --

  test "background image appears in body style when theme with image is active" do
    @theme.background_image.attach(
      io: file_fixture("avatar.png").open,
      filename: "avatar.png",
      content_type: "image/png"
    )
    @user.update!(active_theme: @theme)

    visit our_themes_path

    assert_match(/background-image:\s*url\(/, find("body")[:style])
  end

  test "background image is not in body style when theme has no image" do
    @user.update!(active_theme: @theme)

    visit our_themes_path

    refute_match(/background-image/, find("body")[:style].to_s)
  end
end
