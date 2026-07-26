class AddChatBracketsToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :chat_bracket_before, :string
    add_column :profiles, :chat_bracket_after, :string

    # Mirrors Profile#chat_brackets_unique_per_user exactly: case-sensitive
    # (by design — "guy:" and "GUY:" identify different profiles), COALESCE so
    # Postgres treats NULL like "" for uniqueness (otherwise duplicates like
    # ("guy:", NULL) can slip past the unique index), and a partial WHERE so
    # any number of profiles can still have no brackets set at all — the model
    # skips the check entirely in that case, and without this clause every
    # bracketless profile would collide on the ("", "") tuple.
    add_index :profiles, "user_id, COALESCE(chat_bracket_before, ''), COALESCE(chat_bracket_after, '')",
      unique: true, name: "index_profiles_on_user_id_and_chat_bracket_pair",
      where: "chat_bracket_before IS NOT NULL OR chat_bracket_after IS NOT NULL"
  end
end
