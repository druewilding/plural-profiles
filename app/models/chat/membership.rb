module Chat
  class Membership < ChatRecord
    self.table_name = "chat_memberships"

    ROLES = %w[owner member].freeze

    belongs_to :server, class_name: "Chat::Server"
    belongs_to :user
    belongs_to :default_postable, polymorphic: true, optional: true

    validates :role, inclusion: { in: ROLES }
    validates :user_id, uniqueness: { scope: :server_id }
    validate :default_postable_belongs_to_same_user

    def owner?
      role == "owner"
    end

    private

    def default_postable_belongs_to_same_user
      return unless default_postable
      return if default_postable.user_id == user_id

      errors.add(:default_postable, "must belong to the same user")
    end
  end
end
