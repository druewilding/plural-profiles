class SplitChatBracketsOnProfiles < ActiveRecord::Migration[8.1]
  def change
    remove_index :profiles, [ :user_id, :chat_brackets ]
    remove_column :profiles, :chat_brackets, :string

    add_column :profiles, :chat_bracket_before, :string
    add_column :profiles, :chat_bracket_after, :string

    # Mirrors Profile#chat_brackets_unique_per_user exactly: case-insensitive,
    # NULL treated as "", and only enforced once at least one bracket is set
    # (a bare `unique: true` index is case-sensitive and would happily let two
    # concurrent requests both pass the Ruby validation and land on duplicate
    # rows).
    add_index :profiles,
      "user_id, LOWER(COALESCE(chat_bracket_before, '')), LOWER(COALESCE(chat_bracket_after, ''))",
      unique: true,
      name: "index_profiles_on_user_id_and_chat_bracket_pair",
      where: "chat_bracket_before IS NOT NULL OR chat_bracket_after IS NOT NULL"
  end
end
