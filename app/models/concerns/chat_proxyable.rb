
# Shared by Profile and Group: Tupperbox-style chat proxy brackets
# (chat_bracket_before/chat_bracket_after) that let a user's message body
# select who they're posting as. See Chat::ProxyResolver for the matching
# logic (it has to consider Profile and Group candidates together, so it
# can't live on either model alone).
module ChatProxyable
  extend ActiveSupport::Concern

  included do
    normalizes :chat_bracket_before, with: ->(value) { value.blank? ? nil : value.strip }
    normalizes :chat_bracket_after, with: ->(value) { value.blank? ? nil : value.strip }

    validate :chat_brackets_unique_per_user
  end

  private

  # Bracket pairs must be unique per user across BOTH profiles and groups —
  # if "guy:" were bound to a profile and also to a group for the same user,
  # Chat::ProxyResolver would have no principled way to pick between them.
  # The DB-level partial unique index on each table only catches same-model
  # duplicates; the cross-model case is guarded here instead.
  def chat_brackets_unique_per_user
    return if chat_bracket_before.blank? && chat_bracket_after.blank?

    duplicate = [ Profile, Group ].any? do |klass|
      scope = klass.where(user_id: user_id)
      scope = scope.where.not(id: id) if klass == self.class
      scope.where("COALESCE(chat_bracket_before, '') = ? AND COALESCE(chat_bracket_after, '') = ?",
        chat_bracket_before.to_s, chat_bracket_after.to_s).exists?
    end
    errors.add(:base, "The chat proxy brackets are already used by another profile or group") if duplicate
  end
end
