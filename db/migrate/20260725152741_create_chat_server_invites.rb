class CreateChatServerInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_server_invites do |t|
      t.bigint :server_id, null: false
      t.bigint :created_by_id, null: false
      t.bigint :redeemed_by_id
      t.datetime :redeemed_at
      t.string :token, null: false

      t.timestamps
    end

    add_index :chat_server_invites, :token, unique: true
    add_index :chat_server_invites, :server_id
    add_index :chat_server_invites, :created_by_id
    add_index :chat_server_invites, :redeemed_by_id

    add_foreign_key :chat_server_invites, :chat_servers, column: :server_id
    add_foreign_key :chat_server_invites, :users, column: :created_by_id
    add_foreign_key :chat_server_invites, :users, column: :redeemed_by_id
  end
end
