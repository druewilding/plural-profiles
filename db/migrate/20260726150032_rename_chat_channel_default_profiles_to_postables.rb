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
    # Unlike chat_messages (which keeps a profile_name snapshot, so a
    # group-backed row can roll back to the same "profile was deleted" shape
    # the schema already tolerated), this table's profile_id was NOT NULL
    # with no fallback column at all. A group-backed row has no valid value
    # to put there, so rolling back while one exists would otherwise fail
    # opaquely on the NOT NULL constraint below — raise a clear, actionable
    # error instead.
    group_backed_count = connection.select_value(
      "SELECT COUNT(*) FROM chat_channel_default_postables WHERE postable_type <> 'Profile'"
    ).to_i
    if group_backed_count > 0
      raise ActiveRecord::IrreversibleMigration,
        "#{group_backed_count} chat_channel_default_postables row(s) have a Group as their postable, which " \
        "this migration's down path has no way to represent (profile_id was NOT NULL with no snapshot column). " \
        "Delete or reassign those rows to a Profile before rolling back."
    end

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
