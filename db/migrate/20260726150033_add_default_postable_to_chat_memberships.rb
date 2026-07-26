class AddDefaultPostableToChatMemberships < ActiveRecord::Migration[8.1]
  def up
    add_column :chat_memberships, :default_postable_type, :string
    add_column :chat_memberships, :default_postable_id, :bigint

    execute <<~SQL.squish
      UPDATE chat_memberships SET default_postable_type = 'Profile', default_postable_id = default_profile_id
      WHERE default_profile_id IS NOT NULL
    SQL

    remove_foreign_key :chat_memberships, :profiles, column: "default_profile_id"
    remove_index :chat_memberships, :default_profile_id
    remove_column :chat_memberships, :default_profile_id, :bigint

    add_index :chat_memberships, [ :default_postable_type, :default_postable_id ]
  end

  def down
    add_column :chat_memberships, :default_profile_id, :bigint

    execute <<~SQL.squish
      UPDATE chat_memberships SET default_profile_id = default_postable_id WHERE default_postable_type = 'Profile'
    SQL

    add_index :chat_memberships, :default_profile_id
    add_foreign_key :chat_memberships, :profiles, column: "default_profile_id"

    remove_index :chat_memberships, [ :default_postable_type, :default_postable_id ]
    remove_column :chat_memberships, :default_postable_type, :string
    remove_column :chat_memberships, :default_postable_id, :bigint
  end
end
