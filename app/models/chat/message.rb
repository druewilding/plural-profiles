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
    after_create_commit :broadcast_unread_dots

    private

    def resolve_profile
      if (match = Profile.resolve_chat_proxy(user, body))
        self.profile = match[:profile]
        self.body = match[:content]
      end
      self.profile ||= channel&.default_profile_for(user) || channel&.server&.memberships&.find_by(user_id: user_id)&.default_profile
      self.profile_name ||= profile&.name
    end

    # Lights up the sidebar dots live for every other server member. This is
    # optimistic — it doesn't recheck each recipient's actual read state — but
    # a brand new message is definitionally unread for everyone but its
    # author, and it's just an enhancement on top of the per-request Ruby
    # computation (Chat::ChannelRead.unread_*_for), which stays the source of
    # truth and self-heals on the next page load regardless of whether this
    # broadcast reaches anyone. A recipient actively viewing this exact
    # channel does still receive the "on" push (there's no presence tracking
    # to know otherwise) — the CSS rule suppressing `.unread-dot` inside the
    # active sidebar row is what keeps that from visibly flashing on for them.
    def broadcast_unread_dots
      server = channel.server
      server.members.where.not(id: user_id).find_each do |recipient|
        broadcast_replace_to [ recipient, server, :chat_channel_pane ],
          target: "channel_#{channel.id}_sidebar_dot",
          partial: "chat/shared/channel_dot", locals: { channel: channel, unread: true }
        broadcast_replace_to [ recipient, :chat_server_rail ],
          target: "server_#{server.id}_rail_dot",
          partial: "chat/shared/server_dot", locals: { server: server, unread: true }
      end
    end
  end
end
