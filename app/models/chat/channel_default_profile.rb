module Chat
  class ChannelDefaultProfile < ChatRecord
    self.table_name = "chat_channel_default_profiles"

    belongs_to :channel, class_name: "Chat::Channel"
    belongs_to :user
    belongs_to :profile

    validates :user_id, uniqueness: { scope: :channel_id }
    validate :profile_belongs_to_same_user

    private

    def profile_belongs_to_same_user
      return unless profile
      return if profile.user_id == user_id

      errors.add(:profile, "must belong to the same user")
    end
  end
end
