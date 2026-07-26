class RenameChatChannelDefaultProfilesToPostables < ActiveRecord::Migration[8.1]
  def up
    # PostgreSQL's rename_table already renames indexes that follow the old
    # table's naming convention, so the channel_id/user_id unique index comes
    # along for free — no explicit rename_index needed (and attempting one
    # against the old name errors, since it no longer exists post-rename).
    rename_table :chat_channel_default_profiles, :chat_channel_default_postables

    add_column :chat_channel_default_postables, :postable_type, :string
    add_column :chat_channel_default_postables, :postable_id, :bigint

    execute <<~SQL.squish
      UPDATE chat_channel_default_postables SET postable_type = 'Profile', postable_id = profile_id
    SQL

    change_column_null :chat_channel_default_postables, :postable_type, false
    change_column_null :chat_channel_default_postables, :postable_id, false

    remove_foreign_key :chat_channel_default_postables, :profiles
    remove_index :chat_channel_default_postables, :profile_id
    remove_column :chat_channel_default_postables, :profile_id, :bigint

    add_index :chat_channel_default_postables, [ :postable_type, :postable_id ]
  end

  def down
    add_column :chat_channel_default_postables, :profile_id, :bigint

    execute <<~SQL.squish
      UPDATE chat_channel_default_postables SET profile_id = postable_id WHERE postable_type = 'Profile'
    SQL

    change_column_null :chat_channel_default_postables, :profile_id, false
    add_index :chat_channel_default_postables, :profile_id
    add_foreign_key :chat_channel_default_postables, :profiles

    remove_index :chat_channel_default_postables, [ :postable_type, :postable_id ]
    remove_column :chat_channel_default_postables, :postable_type, :string
    remove_column :chat_channel_default_postables, :postable_id, :bigint

    rename_table :chat_channel_default_postables, :chat_channel_default_profiles
  end
end
