module Chat
  class Channel < ChatRecord
    self.table_name = "chat_channels"

    NAME_FORMAT = /\A[a-z0-9][a-z0-9-]*\z/

    belongs_to :server, class_name: "Chat::Server"
    belongs_to :theme, optional: true

    has_many :messages, class_name: "Chat::Message", foreign_key: :channel_id, dependent: :destroy
    has_many :channel_default_profiles, class_name: "Chat::ChannelDefaultProfile", foreign_key: :channel_id, dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :server_id },
      format: { with: NAME_FORMAT, message: "can only contain lowercase letters, numbers, and hyphens" }

    def to_param
      name
    end

    def default_profile_for(user)
      channel_default_profiles.find_by(user: user)&.profile
    end
  end
end
