class DuplicationWizard < ApplicationRecord
  belongs_to :user
  belongs_to :group

  scope :stale, -> { where(updated_at: ...24.hours.ago) }
end
