class GroupProfile < ApplicationRecord
  belongs_to :group
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :group_id }
  validate :same_user

  private

  def same_user
    return unless group && profile
    return if group.user_id == profile.user_id

    errors.add(:profile, "must belong to the same user")
  end
end
