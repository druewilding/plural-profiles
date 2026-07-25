class CreateChatServers < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_servers do |t|
      t.string :uuid, null: false
      t.bigint :owner_id, null: false
      t.string :name, null: false
      t.string :subtitle
      t.string :avatar_shape, null: false, default: "rounded"
      t.string :avatar_alt_text
      t.bigint :theme_id

      t.timestamps
    end

    add_index :chat_servers, :uuid, unique: true
    add_index :chat_servers, :owner_id
    add_index :chat_servers, :theme_id

    add_foreign_key :chat_servers, :users, column: :owner_id
    add_foreign_key :chat_servers, :themes, on_delete: :nullify
  end
end
