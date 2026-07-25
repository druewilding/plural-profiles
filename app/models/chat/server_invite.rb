module Chat
  class ServerInvite < ChatRecord
    self.table_name = "chat_server_invites"

    belongs_to :server, class_name: "Chat::Server"
    belongs_to :created_by, class_name: "User"
    belongs_to :redeemed_by, class_name: "User", optional: true

    before_validation :generate_token, on: :create

    validates :token, presence: true, uniqueness: true

    scope :unredeemed, -> { where(redeemed_by_id: nil) }

    def to_param
      token
    end

    def redeemed?
      redeemed_by_id.present?
    end

    def redeem!(user)
      with_lock do
        raise ActiveRecord::RecordInvalid.new(self), "Invite has already been used" if redeemed?

        update!(redeemed_by: user, redeemed_at: Time.current)
      end
    end

    private

    def generate_token
      self.token ||= PluralProfilesUuid.generate
    end
  end
end
