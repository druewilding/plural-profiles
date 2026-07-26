module Chat
  class ChannelDefaultPostable < ChatRecord
    self.table_name = "chat_channel_default_postables"

    belongs_to :channel, class_name: "Chat::Channel"
    belongs_to :user
    belongs_to :postable, polymorphic: true

    validates :user_id, uniqueness: { scope: :channel_id }
    validate :postable_belongs_to_same_user

    private

    def postable_belongs_to_same_user
      return unless postable
      return if postable.user_id == user_id

      errors.add(:postable, "must belong to the same user")
    end
  end
end
