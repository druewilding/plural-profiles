class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.bigint :channel_id, null: false
      t.bigint :user_id, null: false
      t.bigint :profile_id
      t.string :profile_name, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :chat_messages, [ :channel_id, :created_at ]
    add_index :chat_messages, :user_id
    add_index :chat_messages, :profile_id

    add_foreign_key :chat_messages, :chat_channels, column: :channel_id
    add_foreign_key :chat_messages, :users
    add_foreign_key :chat_messages, :profiles
  end
end
