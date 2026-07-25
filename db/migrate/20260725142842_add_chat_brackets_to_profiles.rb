class AddChatBracketsToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :chat_brackets, :string
    add_index :profiles, [ :user_id, :chat_brackets ], unique: true
  end
end
