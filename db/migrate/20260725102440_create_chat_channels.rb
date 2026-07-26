class CreateChatChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_channels do |t|
      t.bigint :server_id, null: false
      t.string :name, null: false
      t.string :subtitle
      t.bigint :theme_id

      t.timestamps
    end

    add_index :chat_channels, [ :server_id, :name ], unique: true
    add_index :chat_channels, :theme_id

    add_foreign_key :chat_channels, :chat_servers, column: :server_id
    add_foreign_key :chat_channels, :themes, on_delete: :nullify
  end
end
