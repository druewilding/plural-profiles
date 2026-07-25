class SplitChatBracketsOnProfiles < ActiveRecord::Migration[8.1]
  def change
    remove_index :profiles, [ :user_id, :chat_brackets ]
    remove_column :profiles, :chat_brackets, :string

    add_column :profiles, :chat_bracket_before, :string
    add_column :profiles, :chat_bracket_after, :string
    add_index :profiles, [ :user_id, :chat_bracket_before, :chat_bracket_after ], unique: true, name: "index_profiles_on_user_id_and_chat_bracket_pair"
  end
end
