module Chat
  class ChannelRead < ChatRecord
    self.table_name = "chat_channel_reads"

    belongs_to :user
    belongs_to :channel, class_name: "Chat::Channel"

    validates :last_read_at, presence: true
    validates :channel_id, uniqueness: { scope: :user_id }

    def self.mark_read!(user, channel)
      upsert({ user_id: user.id, channel_id: channel.id, last_read_at: Time.current }, unique_by: %i[user_id channel_id])
    end

    # Deliberately three small queries combined in Ruby rather than one complex
    # join — per-user channel/server counts are small, and this stays easy to
    # read as the source of truth both for full-page renders and for
    # recomputing state on demand when broadcasting a live update.
    def self.unread_channel_ids_for(user)
      channel_ids = Chat::Channel.where(server_id: user.chat_servers.select(:id)).pluck(:id)
      return [] if channel_ids.empty?

      reads = where(user: user, channel_id: channel_ids).pluck(:channel_id, :last_read_at).to_h
      last_activity = Chat::Message.where(channel_id: channel_ids).group(:channel_id).maximum(:created_at)
      channel_ids.select do |channel_id|
        latest = last_activity[channel_id]
        latest && (reads[channel_id].nil? || reads[channel_id] < latest)
      end
    end

    def self.unread_server_ids_for(user)
      Chat::Channel.where(id: unread_channel_ids_for(user)).distinct.pluck(:server_id).to_set
    end
  end
end
