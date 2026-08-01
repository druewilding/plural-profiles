class AddSubtitleToChatChannelsAndServers < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_channels, :subtitle, :string
    add_column :chat_servers, :subtitle, :string
  end
end
