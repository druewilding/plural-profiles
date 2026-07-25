class SplitChatBracketsOnProfiles < ActiveRecord::Migration[8.1]
  def change
    remove_index :profiles, [ :user_id, :chat_brackets ]
    remove_column :profiles, :chat_brackets, :string

    add_column :profiles, :chat_bracket_before, :string
    add_column :profiles, :chat_bracket_after, :string

    # Mirrors Profile#chat_brackets_unique_per_user exactly: case-sensitive
    # (by design — "guy:" and "GUY:" identify different profiles). No partial
    # WHERE clause needed for the "no brackets set" case either — Postgres
    # already treats every NULL as distinct for a unique index, so any number
    # of profiles can have both columns NULL without colliding.
    add_index :profiles, [ :user_id, :chat_bracket_before, :chat_bracket_after ], unique: true, name: "index_profiles_on_user_id_and_chat_bracket_pair"
  end
end
