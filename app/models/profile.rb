class Profile < ApplicationRecord
  include HasAvatar
  include HasLabels

  # Order here is the display order on the profile form. Numbers are not part of
  # the stored/canonical name — Discord's numbering churns as hearts are added,
  # so heart_emojis and emoji codes in text are keyed on the name alone.
  HEART_EMOJIS = [
    "dewdrop_heart",
    "spring_heart",
    "hunter_heart",
    "woods_heart",
    "seafoam_heart",
    "fern_heart",
    "moss_heart",
    "bramble_heart",
    "wild_heart",
    "aqua_heart",
    "ocean_heart",
    "storm_heart",
    "abyss_heart",
    "frozen_heart",
    "ice_heart",
    "cornflower_heart",
    "azure_heart",
    "nightsky_heart",
    "haunted_heart",
    "mist_heart",
    "lavender_heart",
    "violet_heart",
    "aubegine_heart",
    "shadow_heart",
    "inky_heart",
    "blossom_heart",
    "burgundy_heart",
    "arcane_heart",
    "void_heart",
    "vulnerable_heart",
    "filthy_heart",
    "passionate_heart",
    "blackened_heart",
    "hungry_heart",
    "princess_heart",
    "red_heart",
    "murder_heart",
    "dawn_heart",
    "peach_heart",
    "fawn_heart",
    "fur_heart",
    "soil_heart",
    "nox_heart",
    "cadbury_heart",
    "maroon_heart",
    "sunshine_heart"
  ].freeze

  belongs_to :user
  belongs_to :theme, optional: true
  belongs_to :copied_from, class_name: "Profile", optional: true
  has_many :copies, class_name: "Profile", foreign_key: :copied_from_id, dependent: :nullify
  has_many :group_profiles, dependent: :destroy
  has_many :groups, through: :group_profiles

  has_many :chat_messages, class_name: "Chat::Message", foreign_key: :profile_id, dependent: :nullify
  has_many :chat_server_memberships, class_name: "Chat::Membership", foreign_key: :default_profile_id, dependent: :nullify
  has_many :chat_channel_default_profiles, class_name: "Chat::ChannelDefaultProfile", foreign_key: :profile_id, dependent: :destroy

  before_create :generate_uuid

  normalizes :chat_brackets, with: ->(brackets) { brackets.blank? ? nil : brackets.strip }

  validates :name, presence: true
  validates :uuid, uniqueness: true
  validates :chat_brackets, uniqueness: { scope: :user_id, case_sensitive: false }, allow_blank: true

  validate :heart_emojis_are_valid
  validate :chat_brackets_contains_placeholder

  def to_param
    uuid
  end

  # Returns copies of this profile that have ALL of the given labels.
  # Follows the full copy lineage chain (copies of copies) using a recursive CTE,
  # so a grandchild copy (A → B → C) is found when searching from A.
  def copies_with_labels(labels)
    sql = <<~SQL.squish
      WITH RECURSIVE copy_tree AS (
        SELECT id FROM profiles WHERE copied_from_id = :root_id AND user_id = :user_id
        UNION
        SELECT p.id FROM profiles p
        INNER JOIN copy_tree ct ON p.copied_from_id = ct.id
        WHERE p.user_id = :user_id
      )
      SELECT id FROM copy_tree
    SQL
    all_copy_ids = Profile.connection.select_values(
      Profile.sanitize_sql([ sql, root_id: id, user_id: user_id ])
    ).map(&:to_i)
    Profile.where(id: all_copy_ids, user_id: user_id).where("labels @> ?", labels.to_json)
  end

  def self.heart_emoji_display_name(heart)
    heart.tr("_", " ")
  end

  # Resolve a heart name to its canonical HEART_EMOJIS entry.
  # Accepts both the bare name ("aqua_heart") and older pastes that still carry
  # a number prefix ("11_aqua_heart") — the number is stripped and ignored, since
  # Discord's numbering has changed under us before and will again.
  def self.resolve_heart_emoji(name)
    bare = name.to_s.downcase.sub(/\A\d+_?/, "")
    bare if HEART_EMOJIS.include?(bare)
  end

  def heart_emoji_display_name(heart)
    self.class.heart_emoji_display_name(heart)
  end

  # Tupperbox-style proxying: given a user and a raw chat message body, finds
  # the user's own profile (if any) whose chat_brackets template matches —
  # e.g. brackets "guy: text" matches a body starting with "guy: " (case-
  # insensitively), brackets "{text}" matches a body wrapped in braces. When
  # more than one profile matches, the one with the longer (more specific)
  # brackets wins. Returns nil, or a hash with the matched profile and the
  # message content with the brackets stripped off.
  def self.resolve_chat_proxy(user, body)
    return if body.blank?
    user.profiles.where.not(chat_brackets: nil).filter_map { |profile|
      prefix, suffix = profile.chat_brackets.split("text", 2)
      suffix = suffix.to_s
      next unless body.length >= prefix.length + suffix.length
      next unless body[0, prefix.length].casecmp?(prefix)
      next unless suffix.blank? || body[-suffix.length, suffix.length].to_s.casecmp?(suffix)
      content_end = suffix.blank? ? body.length : body.length - suffix.length
      content = body[prefix.length...content_end].to_s.strip
      next if content.blank?
      { profile: profile, content: content, specificity: prefix.length + suffix.length }
    }.max_by { |match| match[:specificity] }
  end

  # Normalizes any number-prefixed entries (e.g. a stale form submitted after a
  # renumber) to their bare canonical form, so only genuinely unknown hearts
  # fail validation.
  def heart_emojis=(values)
    super(Array(values).map { |value| value.blank? ? value : (self.class.resolve_heart_emoji(value) || value) })
  end

  private

  def generate_uuid
    self.uuid = PluralProfilesUuid.generate
  end

  def heart_emojis_are_valid
    return if heart_emojis.blank?
    invalid = heart_emojis - HEART_EMOJIS
    errors.add(:heart_emojis, "contains invalid hearts: #{invalid.join(', ')}") if invalid.any?
  end

  def chat_brackets_contains_placeholder
    return if chat_brackets.blank?
    if chat_brackets.scan("text").size != 1
      return errors.add(:chat_brackets, "must contain the word \"text\" exactly once, e.g. \"guy: text\" or \"{text}\"")
    end
    prefix, suffix = chat_brackets.split("text", 2)
    errors.add(:chat_brackets, "needs something before or after \"text\", e.g. \"guy: text\" or \"{text}\"") if prefix.blank? && suffix.blank?
  end
end
