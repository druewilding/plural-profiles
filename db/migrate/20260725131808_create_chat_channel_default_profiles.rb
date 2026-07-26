class CreateChatChannelDefaultProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_channel_default_profiles do |t|
      t.bigint :channel_id, null: false
      t.bigint :user_id, null: false
      t.bigint :profile_id, null: false

      t.timestamps
    end

    add_index :chat_channel_default_profiles, [ :channel_id, :user_id ], unique: true
    add_index :chat_channel_default_profiles, :profile_id

    add_foreign_key :chat_channel_default_profiles, :chat_channels, column: :channel_id
    add_foreign_key :chat_channel_default_profiles, :users
    add_foreign_key :chat_channel_default_profiles, :profiles
  end
end
