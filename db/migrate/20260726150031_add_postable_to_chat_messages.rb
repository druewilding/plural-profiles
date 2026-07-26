class AddPostableToChatMessages < ActiveRecord::Migration[8.1]
  def up
    add_reference :chat_messages, :postable, polymorphic: true, index: true
    add_column :chat_messages, :postable_name, :string

    execute <<~SQL.squish
      UPDATE chat_messages SET postable_type = 'Profile', postable_id = profile_id, postable_name = profile_name
    SQL

    change_column_null :chat_messages, :postable_name, false

    remove_foreign_key :chat_messages, :profiles
    remove_index :chat_messages, :profile_id
    remove_column :chat_messages, :profile_id, :bigint
    remove_column :chat_messages, :profile_name, :string
  end

  def down
    add_column :chat_messages, :profile_id, :bigint
    add_column :chat_messages, :profile_name, :string
    add_index :chat_messages, :profile_id
    add_foreign_key :chat_messages, :profiles

    execute <<~SQL.squish
      UPDATE chat_messages SET profile_id = postable_id, profile_name = postable_name
      WHERE postable_type = 'Profile'
    SQL

    change_column_null :chat_messages, :profile_name, false

    remove_column :chat_messages, :postable_type, :string
    remove_column :chat_messages, :postable_id, :bigint
    remove_column :chat_messages, :postable_name, :string
  end
end
