class AddChatBracketsToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :chat_bracket_before, :string
    add_column :groups, :chat_bracket_after, :string

    # Mirrors AddChatBracketsToProfiles exactly (see that migration for the
    # full rationale) — catches same-table duplicates at the DB level. A
    # profile and a group sharing the same bracket pair for the same user is
    # a separate case this index can't catch (it's per-table); that's guarded
    # by ChatProxyable#chat_brackets_unique_per_user instead.
    add_index :groups, "user_id, COALESCE(chat_bracket_before, ''), COALESCE(chat_bracket_after, '')",
      unique: true, name: "index_groups_on_user_id_and_chat_bracket_pair",
      where: "chat_bracket_before IS NOT NULL OR chat_bracket_after IS NOT NULL"
  end
end
