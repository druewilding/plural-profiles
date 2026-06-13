require "application_system_test_case"

class SpoilerTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
  end

  test "clicking a spoiler reveals it and updates ARIA attributes" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Spoiler Tester"
    fill_in "Description", with: "the password is ||super secret||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"
    assert_equal "false", spoiler[:"aria-expanded"]
    assert_equal "Hidden content, click to reveal", spoiler[:"aria-label"]

    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_text "super secret"
    assert_equal "true", spoiler[:"aria-expanded"]
    assert_nil spoiler[:"aria-label"]
  end

  test "clicking a revealed spoiler hides it again and restores ARIA" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Toggle Tester"
    fill_in "Description", with: "||hidden text||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_equal "true", spoiler[:"aria-expanded"]
    assert_nil spoiler[:"aria-label"]

    spoiler.click
    assert_no_selector ".spoiler.spoiler--revealed"
    assert_equal "false", spoiler[:"aria-expanded"]
    assert_equal "Hidden content, click to reveal", spoiler[:"aria-label"]
  end

  test "spoiler can be toggled with Enter key" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Keyboard Tester"
    fill_in "Description", with: "||keyboard secret||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"

    spoiler.send_keys(:enter)
    assert_selector ".spoiler.spoiler--revealed"
    assert_equal "true", spoiler[:"aria-expanded"]

    spoiler.send_keys(:enter)
    assert_no_selector ".spoiler.spoiler--revealed"
    assert_equal "false", spoiler[:"aria-expanded"]
  end

  test "spoiler can be toggled with Space key" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Space Tester"
    fill_in "Description", with: "||space secret||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"

    spoiler.send_keys(:space)
    assert_selector ".spoiler.spoiler--revealed"
    assert_equal "true", spoiler[:"aria-expanded"]

    spoiler.send_keys(:space)
    assert_no_selector ".spoiler.spoiler--revealed"
    assert_equal "false", spoiler[:"aria-expanded"]
  end

  test "spoiler has correct accessibility attributes" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "A11y Tester"
    fill_in "Description", with: "||accessible||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_equal "button", spoiler[:"role"]
    assert_equal "0", spoiler[:"tabindex"]
    assert_equal "false", spoiler[:"aria-expanded"]
    assert_equal "Hidden content, click to reveal", spoiler[:"aria-label"]
  end

  test "multiline spoiler is fully revealed on click" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Multiline Tester"
    fill_in "Description", with: "||line one\nline two||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler")
    assert_no_selector ".spoiler.spoiler--revealed"

    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_text "line one"
    assert_text "line two"
  end

  test "spoiler inside code block is not converted" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Code Tester"
    fill_in "Description", with: "Use <code>||text||</code> for spoilers"
    click_button "Create profile"
    assert_text "Profile created."

    assert_selector "code", text: "||text||"
    assert_no_selector "code .spoiler"
  end

  test "spoiler controller does not interfere with details keyboard navigation" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Details Keyboard Tester"
    fill_in "Description", with: "<details><summary>More info</summary>Hidden detail</details>"
    click_button "Create profile"
    assert_text "Profile created."

    within(".profile-description") do
      summary = find("summary", text: "More info")
      assert_no_selector "details[open]"

      summary.send_keys(:enter)
      assert_selector "details[open]"
      assert_text "Hidden detail"

      summary.send_keys(:enter)
      assert_no_selector "details[open]"
    end
  end

  test "details close hint is hidden when collapsed and visible when open" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Details Close Hint Tester"
    fill_in "Description", with: "<details><summary>Expand me</summary>Some content</details>"
    click_button "Create profile"
    assert_text "Profile created."

    within(".profile-description") do
      assert_no_selector "details[open]"
      assert_no_selector ".details-close"

      find("summary", text: "Expand me").click
      assert_selector "details[open]"
      assert_selector ".details-close", visible: true
    end
  end

  test "clicking the details close hint collapses the details block" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Details Close Click Tester"
    fill_in "Description", with: "<details><summary>Click to open</summary>Inner content</details>"
    click_button "Create profile"
    assert_text "Profile created."

    within(".profile-description") do
      find("summary", text: "Click to open").click
      assert_selector "details[open]"
      assert_text "Inner content"

      find(".details-close").click
      assert_no_selector "details[open]"
    end
  end

  test "details close hint can be activated via keyboard and returns focus to summary" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Details Close Keyboard Tester"
    fill_in "Description", with: "<details><summary>Keyboard open</summary>Keyboard content</details>"
    click_button "Create profile"
    assert_text "Profile created."

    within(".profile-description") do
      find("summary", text: "Keyboard open").click
      assert_selector "details[open]"

      close_btn = find(".details-close")
      close_btn.send_keys(:enter)
      assert_no_selector "details[open]"

      summary = find("summary", text: "Keyboard open")
      assert_equal summary.native, page.driver.browser.switch_to.active_element
    end
  end

  test "details close hint can be activated via Space key" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Details Close Space Tester"
    fill_in "Description", with: "<details><summary>Space open</summary>Space content</details>"
    click_button "Create profile"
    assert_text "Profile created."

    within(".profile-description") do
      find("summary", text: "Space open").click
      assert_selector "details[open]"

      find(".details-close").send_keys(:space)
      assert_no_selector "details[open]"
    end
  end

  # -- Spoiler hint syntax --

  test "hint after spoiler renders spoiler--with-hint span with data attribute" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Hint After Tester"
    fill_in "Description", with: "||the secret||[it is a password]"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler.spoiler--with-hint")
    assert_equal "it is a password", spoiler[:"data-spoiler-hint"]
    assert_equal "Hidden content: it is a password, click to reveal", spoiler[:"aria-label"]
  end

  test "hint before spoiler renders spoiler--with-hint span with data attribute" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Hint Before Tester"
    fill_in "Description", with: "[it is a password]||the secret||"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler.spoiler--with-hint")
    assert_equal "it is a password", spoiler[:"data-spoiler-hint"]
    assert_equal "Hidden content: it is a password, click to reveal", spoiler[:"aria-label"]
  end

  test "hinted spoiler reveals on click and clears aria-label" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Hint Reveal Tester"
    fill_in "Description", with: "||hidden text||[a clue about it]"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler.spoiler--with-hint")
    assert_equal "false", spoiler[:"aria-expanded"]

    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"
    assert_text "hidden text"
    assert_equal "true", spoiler[:"aria-expanded"]
    assert_nil spoiler[:"aria-label"]
  end

  test "hinted spoiler restores hint-aware aria-label when hidden again" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Hint Restore Tester"
    fill_in "Description", with: "||content||[descriptive hint]"
    click_button "Create profile"
    assert_text "Profile created."

    spoiler = find(".spoiler.spoiler--with-hint")
    spoiler.click
    assert_selector ".spoiler.spoiler--revealed"

    spoiler.click
    assert_no_selector ".spoiler.spoiler--revealed"
    assert_equal "false", spoiler[:"aria-expanded"]
    assert_equal "Hidden content: descriptive hint, click to reveal", spoiler[:"aria-label"]
  end

  test "plain spoiler alongside hinted spoiler both work independently" do
    within(".site-header") { click_link "New profile" }
    fill_in "Name", with: "Mixed Spoilers Tester"
    fill_in "Description", with: "||plain|| and ||hinted||[a clue]"
    click_button "Create profile"
    assert_text "Profile created."

    assert_selector ".spoiler", count: 2
    assert_selector ".spoiler.spoiler--with-hint", count: 1
    assert_no_selector ".spoiler:not(.spoiler--with-hint).spoiler--with-hint"

    hinted = find(".spoiler.spoiler--with-hint")
    assert_equal "a clue", hinted[:"data-spoiler-hint"]
  end
end
