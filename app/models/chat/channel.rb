module Chat
  class Channel < ChatRecord
    self.table_name = "chat_channels"

    belongs_to :server, class_name: "Chat::Server"
    belongs_to :theme, optional: true

    has_many :messages, class_name: "Chat::Message", foreign_key: :channel_id, dependent: :destroy
    has_many :channel_default_profiles, class_name: "Chat::ChannelDefaultProfile", foreign_key: :channel_id, dependent: :destroy

    before_create :generate_uuid

    validates :name, presence: true, uniqueness: { scope: :server_id }
    validates :uuid, uniqueness: true

    def to_param
      uuid
    end

    def default_profile_for(user)
      channel_default_profiles.find_by(user: user)&.profile
    end

    private

    def generate_uuid
      self.uuid = PluralProfilesUuid.generate
    end
  end
end
