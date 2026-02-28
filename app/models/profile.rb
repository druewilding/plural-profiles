class Profile < ApplicationRecord
  include HasAvatar

  belongs_to :user
  has_many :group_profiles, dependent: :destroy
  has_many :groups, through: :group_profiles

  before_create :generate_uuid

  validates :name, presence: true
  validates :uuid, uniqueness: true
  validates :created_at, comparison: { less_than_or_equal_to: -> { Time.current + 1.minute }, message: "can't be in the future" }, allow_nil: true
  validates :updated_at, comparison: { less_than_or_equal_to: -> { Time.current + 1.minute }, message: "can't be in the future" }, allow_nil: true
  validate :updated_at_not_before_created_at

  def to_param
    uuid
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

  def updated_at_not_before_created_at
    return unless updated_at && created_at
    errors.add(:updated_at, "can't be before created at") if updated_at < created_at
  end
end
