class RenameSubtitleToDescriptionOnChatChannelsAndServers < ActiveRecord::Migration[8.1]
  def change
    rename_column :chat_channels, :subtitle, :description
    rename_column :chat_servers, :subtitle, :description
  end
end
