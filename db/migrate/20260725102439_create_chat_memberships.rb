class CreateChatMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_memberships do |t|
      t.bigint :server_id, null: false
      t.bigint :user_id, null: false
      t.bigint :default_profile_id
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :chat_memberships, [ :server_id, :user_id ], unique: true
    add_index :chat_memberships, :user_id
    add_index :chat_memberships, :default_profile_id

    add_foreign_key :chat_memberships, :chat_servers, column: :server_id
    add_foreign_key :chat_memberships, :users
    add_foreign_key :chat_memberships, :profiles, column: :default_profile_id
  end
end
