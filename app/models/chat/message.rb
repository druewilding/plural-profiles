module Chat
  class Message < ChatRecord
    self.table_name = "chat_messages"

    belongs_to :channel, class_name: "Chat::Channel"
    belongs_to :user
    belongs_to :profile, optional: true

    validates :body, presence: true
    validates :profile_id, presence: true, on: :create
    validates :profile_name, presence: true

    before_validation :resolve_profile, on: :create

    private

    def resolve_profile
      self.profile ||= channel&.server&.memberships&.find_by(user_id: user_id)&.default_profile
      self.profile_name ||= profile&.name
    end
  end
end
