class CreateChatChannelReads < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_channel_reads do |t|
      t.bigint :user_id, null: false
      t.bigint :channel_id, null: false
      t.datetime :last_read_at, null: false

      t.timestamps
    end

    add_index :chat_channel_reads, [ :user_id, :channel_id ], unique: true

    add_foreign_key :chat_channel_reads, :users
    add_foreign_key :chat_channel_reads, :chat_channels, column: :channel_id
  end
end
