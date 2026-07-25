require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "requires name" do
    profile = Profile.new(user: users(:one))
    assert_not profile.valid?
    assert_includes profile.errors[:name], "can't be blank"
  end

  test "generates uuid on create" do
    profile = users(:one).profiles.create!(name: "New Profile")
    assert_not_nil profile.uuid
    assert_match(/\A[0-9a-f-]{36}\z/, profile.uuid)
  end

  test "uuid must be unique" do
    existing = profiles(:alice)
    profile = Profile.new(user: users(:two), name: "Dupe", uuid: existing.uuid)
    assert_not profile.valid?
    assert_includes profile.errors[:uuid], "has already been taken"
  end

  test "to_param returns uuid" do
    profile = profiles(:alice)
    assert_equal profile.uuid, profile.to_param
  end

  test "belongs to user" do
    assert_equal users(:one), profiles(:alice).user
  end

  test "has many groups through group_profiles" do
    assert_includes profiles(:alice).groups, groups(:friends)
  end

  test "can attach avatar" do
    profile = profiles(:alice)
    profile.avatar.attach(
      io: File.open(file_fixture("avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
    assert profile.avatar.attached?
  end

  test "rejects non-image avatar" do
    profile = profiles(:alice)
    profile.avatar.attach(
      io: StringIO.new("<script>alert('xss')</script>"),
      filename: "evil.html",
      content_type: "text/html"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:avatar], "must be a JPG/JPEG, PNG, or WebP image"
  end

  test "rejects avatar over 2 MB" do
    profile = profiles(:alice)
    profile.avatar.attach(
      io: StringIO.new("a" * (HasAvatar::AVATAR_MAX_SIZE + 1)),
      filename: "toobig.png",
      content_type: "image/png"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:avatar], "must be 2 MB or less"
  end

  # Timestamp validations

  test "created_at in the past is valid" do
    profile = Profile.new(user: users(:one), name: "Test", created_at: 1.day.ago)
    profile.valid?
    assert_empty profile.errors[:created_at]
  end

  test "created_at in the future is valid" do
    profile = Profile.new(user: users(:one), name: "Test", created_at: 2.minutes.from_now)
    profile.valid?
    assert_empty profile.errors[:created_at]
  end

  # Heart emojis

  test "heart_emojis defaults to empty array" do
    profile = users(:one).profiles.create!(name: "Heartless")
    assert_equal [], profile.heart_emojis
  end

  test "valid heart emojis are accepted" do
    profile = profiles(:alice)
    profile.heart_emojis = %w[dewdrop_heart red_heart]
    assert profile.valid?
  end

  test "invalid heart emoji names are rejected" do
    profile = profiles(:alice)
    profile.heart_emojis = %w[dewdrop_heart fake_heart]
    assert_not profile.valid?
    assert profile.errors[:heart_emojis].any? { |e| e.include?("fake_heart") }
  end

  test "assigning heart_emojis normalizes old number prefixes to their bare form" do
    profile = profiles(:alice)
    profile.heart_emojis = %w[13_storm_heart 50cadbury_heart]
    assert_equal %w[storm_heart cadbury_heart], profile.heart_emojis
    assert profile.valid?
  end

  test "assigning heart_emojis leaves genuinely unknown hearts untouched so they still fail validation" do
    profile = profiles(:alice)
    profile.heart_emojis = %w[dewdrop_heart 99_fake_heart]
    assert_equal %w[dewdrop_heart 99_fake_heart], profile.heart_emojis
    assert_not profile.valid?
    assert profile.errors[:heart_emojis].any? { |e| e.include?("99_fake_heart") }
  end

  test "assigning heart_emojis normalizes uppercase and mixed case" do
    profile = profiles(:alice)
    profile.heart_emojis = %w[11_AQUA_HEART Red_Heart]
    assert_equal %w[aqua_heart red_heart], profile.heart_emojis
    assert profile.valid?
  end

  test "resolve_heart_emoji is case-insensitive" do
    assert_equal "aqua_heart", Profile.resolve_heart_emoji("11_AQUA_HEART")
    assert_equal "aqua_heart", Profile.resolve_heart_emoji("AQUA_HEART")
    assert_equal "aqua_heart", Profile.resolve_heart_emoji("Aqua_Heart")
  end

  test "heart_emoji_display_name formats name" do
    profile = profiles(:alice)
    assert_equal "dewdrop heart", profile.heart_emoji_display_name("dewdrop_heart")
    assert_equal "cadbury heart", profile.heart_emoji_display_name("cadbury_heart")
  end

  test "HEART_EMOJIS constant contains expected hearts" do
    assert_includes Profile::HEART_EMOJIS, "dewdrop_heart"
    assert_includes Profile::HEART_EMOJIS, "red_heart"
    assert_equal 46, Profile::HEART_EMOJIS.size
  end

  test "resolve_heart_emoji returns canonical name for bare name" do
    assert_equal "aqua_heart", Profile.resolve_heart_emoji("aqua_heart")
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("cadbury_heart")
  end

  test "resolve_heart_emoji strips a number prefix regardless of what number it is" do
    assert_equal "aqua_heart", Profile.resolve_heart_emoji("11_aqua_heart")
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("50cadbury_heart")
    assert_equal "dewdrop_heart", Profile.resolve_heart_emoji("01_dewdrop_heart")
    assert_equal "red_heart", Profile.resolve_heart_emoji("36_red_heart")
    assert_equal "red_heart", Profile.resolve_heart_emoji("999_red_heart")
  end

  test "resolve_heart_emoji handles cadbury's no-underscore number prefix in every form" do
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("cadbury_heart")
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("50cadbury_heart")
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("51cadbury_heart")
    assert_equal "cadbury_heart", Profile.resolve_heart_emoji("50_cadbury_heart")
  end

  test "resolve_heart_emoji returns nil for unknown name" do
    assert_nil Profile.resolve_heart_emoji("fake_heart")
    assert_nil Profile.resolve_heart_emoji("99_fake_heart")
  end

  # -- labels --

  test "labels defaults to empty array" do
    profile = users(:one).profiles.create!(name: "Labels Test")
    assert_equal [], profile.labels
  end

  test "labels_text= parses comma-separated string into array" do
    profile = profiles(:alice)
    profile.labels_text = "safe, work, close friends"
    assert_equal [ "safe", "work", "close friends" ], profile.labels
  end

  test "labels_text= trims whitespace and rejects blanks" do
    profile = profiles(:alice)
    profile.labels_text = "  safe ,, work ,  "
    assert_equal [ "safe", "work" ], profile.labels
  end

  test "labels_text= deduplicates entries" do
    profile = profiles(:alice)
    profile.labels_text = "safe, safe, work"
    assert_equal [ "safe", "work" ], profile.labels
  end

  test "labels_text returns labels joined with comma and space" do
    profile = profiles(:alice)
    profile.labels = [ "safe", "work" ]
    assert_equal "safe, work", profile.labels_text
  end

  test "labels_text returns empty string when no labels" do
    profile = profiles(:alice)
    profile.labels = []
    assert_equal "", profile.labels_text
  end

  test "normalize_labels cleans up array on validation" do
    profile = profiles(:alice)
    profile.labels = [ "  safe  ", "", "work" ]
    profile.validate
    assert_equal [ "safe", "work" ], profile.labels
  end

  test "labels round-trip through save" do
    profile = users(:one).profiles.create!(name: "Labels RT")
    profile.update!(labels: [ "family", "private" ])
    assert_equal [ "family", "private" ], profile.reload.labels
  end

  test "name_and_label_sort_key uses downcased name so mixed-case sorts correctly" do
    profile = profiles(:alice)
    profile.name = "Zebra"
    assert_equal "zebra", profile.name_and_label_sort_key.first
  end

  test "name_and_label_sort_key sorts unlabelled before labelled" do
    profile = profiles(:alice)
    profile.labels = []
    unlabelled_key = profile.name_and_label_sort_key

    profile.labels = [ "work" ]
    labelled_key = profile.name_and_label_sort_key

    assert (unlabelled_key <=> labelled_key) < 0
  end

  # -- Profile theme association --

  test "profile without a theme is valid" do
    profile = users(:one).profiles.build(name: "Themeless")
    assert profile.valid?
  end

  test "profile with a theme is valid" do
    profile = users(:one).profiles.build(name: "Themed", theme: themes(:dark_forest))
    assert profile.valid?
  end

  test "theme association is accessible via fixture" do
    assert_equal themes(:dark_forest), profiles(:alice).theme
  end

  test "deleting a theme nullifies the profile theme_id" do
    profile = users(:one).profiles.create!(name: "Will Lose Theme", theme: themes(:sunset))
    assert_not_nil profile.theme_id
    themes(:sunset).destroy
    assert_nil profile.reload.theme_id
  end

  # -- Copy lineage (Phase 5) --

  test "copied_from association" do
    original = users(:one).profiles.create!(name: "Original")
    copy = users(:one).profiles.create!(name: "Copy", copied_from: original)
    assert_equal original, copy.copied_from
  end

  test "copies association" do
    original = users(:one).profiles.create!(name: "Original")
    copy1 = users(:one).profiles.create!(name: "Copy 1", copied_from: original)
    copy2 = users(:one).profiles.create!(name: "Copy 2", copied_from: original)
    assert_includes original.copies, copy1
    assert_includes original.copies, copy2
  end

  test "copies_with_labels returns copies that have ALL given labels" do
    original = users(:one).profiles.create!(name: "Original")
    matching = users(:one).profiles.create!(name: "Matching", copied_from: original, labels: [ "blue", "safe" ])
    partial  = users(:one).profiles.create!(name: "Partial",  copied_from: original, labels: [ "blue" ])
    other    = users(:one).profiles.create!(name: "Other",    copied_from: original, labels: [ "red" ])

    result = original.copies_with_labels([ "blue", "safe" ])
    assert_includes result, matching
    assert_not_includes result, partial
    assert_not_includes result, other
  end

  test "copies_with_labels returns empty when no copies match" do
    original = users(:one).profiles.create!(name: "Original")
    users(:one).profiles.create!(name: "Copy", copied_from: original, labels: [ "red" ])
    assert_empty original.copies_with_labels([ "blue" ])
  end

  test "copies_with_labels finds transitive copies (copy of a copy)" do
    original = users(:one).profiles.create!(name: "Original")
    copy_purple = users(:one).profiles.create!(name: "Copy (purple)", copied_from: original, labels: [ "purple" ])
    copy_yellow = users(:one).profiles.create!(name: "Copy (yellow)", copied_from: copy_purple, labels: [ "yellow" ])

    result = original.copies_with_labels([ "yellow" ])
    assert_includes result, copy_yellow
    assert_not_includes result, copy_purple
  end

  test "copies_with_labels finds deeply nested transitive copies" do
    original = users(:one).profiles.create!(name: "Original")
    gen1 = users(:one).profiles.create!(name: "Gen 1", copied_from: original, labels: [ "a" ])
    gen2 = users(:one).profiles.create!(name: "Gen 2", copied_from: gen1, labels: [ "b" ])
    gen3 = users(:one).profiles.create!(name: "Gen 3", copied_from: gen2, labels: [ "c" ])

    result = original.copies_with_labels([ "c" ])
    assert_includes result, gen3
    assert_equal 1, result.count
  end

  test "deleting the original nullifies copied_from_id on copies" do
    original = users(:one).profiles.create!(name: "Original")
    copy = users(:one).profiles.create!(name: "Copy", copied_from: original)
    original.destroy
    assert_nil copy.reload.copied_from_id
  end

  # -- Chat proxy brackets (Phase 3) --

  test "chat brackets are optional" do
    profile = users(:one).profiles.build(name: "No Brackets")
    assert profile.valid?
  end

  test "chat brackets accept a before-only template" do
    profile = users(:one).profiles.build(name: "Guy", chat_bracket_before: "guy:")
    assert profile.valid?
  end

  test "chat brackets accept an after-only template" do
    profile = users(:one).profiles.build(name: "Suffix", chat_bracket_after: "-g")
    assert profile.valid?
  end

  test "chat brackets accept both a before and an after" do
    profile = users(:one).profiles.build(name: "Brace", chat_bracket_before: "{", chat_bracket_after: "}")
    assert profile.valid?
  end

  test "chat brackets normalize blank input to nil" do
    profile = users(:one).profiles.build(name: "Blank", chat_bracket_before: "   ", chat_bracket_after: "   ")
    profile.valid?
    assert_nil profile.chat_bracket_before
    assert_nil profile.chat_bracket_after
  end

  test "chat brackets strip surrounding whitespace" do
    profile = users(:one).profiles.build(name: "Spacey", chat_bracket_before: "  guy:  ", chat_bracket_after: "  !  ")
    profile.valid?
    assert_equal "guy:", profile.chat_bracket_before
    assert_equal "!", profile.chat_bracket_after
  end

  test "chat brackets must be an exact unique before/after combination per user" do
    users(:one).profiles.create!(name: "First", chat_bracket_before: "guy:")
    dupe = users(:one).profiles.build(name: "Second", chat_bracket_before: "guy:")
    assert_not dupe.valid?
    assert_includes dupe.errors[:base], "The chat proxy brackets are already used by another profile"
  end

  test "chat brackets in a different case are treated as distinct, not duplicates" do
    users(:one).profiles.create!(name: "First", chat_bracket_before: "guy:")
    other = users(:one).profiles.build(name: "Second", chat_bracket_before: "GUY:")
    assert other.valid?
  end

  test "chat brackets allow the same before with a different after" do
    users(:one).profiles.create!(name: "First", chat_bracket_before: "guy:")
    other = users(:one).profiles.build(name: "Second", chat_bracket_before: "guy:", chat_bracket_after: "!")
    assert other.valid?
  end

  test "chat brackets can repeat across different users" do
    users(:one).profiles.create!(name: "Mine", chat_bracket_before: "guy:")
    other = users(:two).profiles.build(name: "Theirs", chat_bracket_before: "guy:")
    assert other.valid?
  end

  test "resolve_chat_proxy matches a before-only prefix exactly" do
    profile = users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    match = Profile.resolve_chat_proxy(users(:one), "guy: hello there")
    assert_equal profile, match[:profile]
    assert_equal "hello there", match[:content]
  end

  test "resolve_chat_proxy does not match when the case differs" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Profile.resolve_chat_proxy(users(:one), "Guy: hello there")
    assert_nil Profile.resolve_chat_proxy(users(:one), "GUY: hello there")
  end

  test "chat brackets differing only by case can identify two different profiles" do
    lower = users(:one).profiles.create!(name: "Lowercase Guy", chat_bracket_before: "guy:")
    upper = users(:one).profiles.create!(name: "Uppercase Guy", chat_bracket_before: "GUY:")

    lower_match = Profile.resolve_chat_proxy(users(:one), "guy: hi")
    upper_match = Profile.resolve_chat_proxy(users(:one), "GUY: hi")

    assert_equal lower, lower_match[:profile]
    assert_equal upper, upper_match[:profile]
  end

  test "resolve_chat_proxy matches a before/after wrap" do
    profile = users(:one).profiles.create!(name: "Brace", chat_bracket_before: "{", chat_bracket_after: "}")
    match = Profile.resolve_chat_proxy(users(:one), "{hello there}")
    assert_equal profile, match[:profile]
    assert_equal "hello there", match[:content]
  end

  test "resolve_chat_proxy matches an after-only suffix" do
    profile = users(:one).profiles.create!(name: "Suffix", chat_bracket_after: "-g")
    match = Profile.resolve_chat_proxy(users(:one), "hello there-g")
    assert_equal profile, match[:profile]
    assert_equal "hello there", match[:content]
  end

  test "resolve_chat_proxy returns nil when nothing matches" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Profile.resolve_chat_proxy(users(:one), "just a normal message")
  end

  test "resolve_chat_proxy returns nil for a blank body" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Profile.resolve_chat_proxy(users(:one), "")
  end

  test "resolve_chat_proxy returns nil when the extracted content would be blank" do
    users(:one).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Profile.resolve_chat_proxy(users(:one), "guy:   ")
  end

  test "resolve_chat_proxy never matches another user's profiles" do
    users(:two).profiles.create!(name: "Guy", chat_bracket_before: "guy:")
    assert_nil Profile.resolve_chat_proxy(users(:one), "guy: hello")
  end

  test "resolve_chat_proxy picks the more specific (longer) brackets when more than one matches" do
    short_match = users(:one).profiles.create!(name: "Short", chat_bracket_before: "g")
    long_match = users(:one).profiles.create!(name: "Long", chat_bracket_before: "g:")
    match = Profile.resolve_chat_proxy(users(:one), "g: hello")
    assert_equal long_match, match[:profile]
    assert_not_equal short_match, match[:profile]
    assert_equal "hello", match[:content]
  end
end
