module Chat
  class Server < ChatRecord
    self.table_name = "chat_servers"

    include HasAvatar

    belongs_to :owner, class_name: "User"
    belongs_to :theme, optional: true

    has_many :memberships, class_name: "Chat::Membership", foreign_key: :server_id, dependent: :destroy
    has_many :members, through: :memberships, source: :user
    has_many :channels, class_name: "Chat::Channel", foreign_key: :server_id, dependent: :destroy
    has_many :server_invites, class_name: "Chat::ServerInvite", foreign_key: :server_id, dependent: :destroy

    before_create :generate_uuid

    validates :name, presence: true
    validates :uuid, uniqueness: true

    def to_param
      uuid
    end

    private

    def generate_uuid
      self.uuid = PluralProfilesUuid.generate
    end
  end
end
