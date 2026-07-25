class AddUuidToChatChannels < ActiveRecord::Migration[8.1]
  class MigrationChannel < ApplicationRecord
    self.table_name = "chat_channels"
  end

  def up
    add_column :chat_channels, :uuid, :string
    MigrationChannel.reset_column_information
    MigrationChannel.find_each { |channel| channel.update_column(:uuid, PluralProfilesUuid.generate) }
    change_column_null :chat_channels, :uuid, false
    add_index :chat_channels, :uuid, unique: true
  end

  def down
    remove_index :chat_channels, :uuid
    remove_column :chat_channels, :uuid
  end
end
