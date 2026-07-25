module Chat
  class Membership < ChatRecord
    self.table_name = "chat_memberships"

    ROLES = %w[owner member].freeze

    belongs_to :server, class_name: "Chat::Server"
    belongs_to :user
    belongs_to :default_profile, class_name: "Profile", optional: true

    validates :role, inclusion: { in: ROLES }
    validates :user_id, uniqueness: { scope: :server_id }
    validate :default_profile_belongs_to_same_user

    def owner?
      role == "owner"
    end

    private

    def default_profile_belongs_to_same_user
      return unless default_profile
      return if default_profile.user_id == user_id

      errors.add(:default_profile, "must belong to the same user")
    end
  end
end
