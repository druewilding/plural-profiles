class GroupProfile < ApplicationRecord
  belongs_to :group
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :group_id }
end
