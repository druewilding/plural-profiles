module Chat
  class Message < ChatRecord
    self.table_name = "chat_messages"

    PAGE_SIZE = 30

    belongs_to :channel, class_name: "Chat::Channel"
    belongs_to :user
    belongs_to :profile, optional: true

    # Keyset pagination cursor for scroll-back history. Deliberately a composite
    # (created_at, id) comparison rather than `id <` alone — id order and
    # created_at order usually coincide for organically-created messages, but
    # they can diverge (e.g. backfilled/imported history with an explicit past
    # created_at, inserted after messages that already exist with lower ids),
    # and `id <` alone silently returns messages out of chronological order —
    # or skips/duplicates rows — whenever that happens. id is only a tiebreaker
    # for the (rare) case of two messages with an identical timestamp.
    scope :before_cursor, ->(message) { where("(chat_messages.created_at, chat_messages.id) < (?, ?)", message.created_at, message.id) }

    def self.latest_page(scope = all)
      scope.order(created_at: :desc, id: :desc).limit(PAGE_SIZE).to_a.reverse
    end

    validates :body, presence: true
    validates :profile_id, presence: true, on: :create
    validates :profile_name, presence: true

    before_validation :resolve_profile, on: :create

    after_create_commit -> { broadcast_append_to channel, target: "chat-messages", partial: "chat/messages/message", locals: { message: self } }

    private

    def resolve_profile
      if (match = Profile.resolve_chat_proxy(user, body))
        self.profile = match[:profile]
        self.body = match[:content]
      end
      self.profile ||= channel&.default_profile_for(user) || channel&.server&.memberships&.find_by(user_id: user_id)&.default_profile
      self.profile_name ||= profile&.name
    end
  end
end
