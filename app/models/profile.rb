class Profile < ApplicationRecord
  include HasAvatar

  belongs_to :user
  has_many :group_profiles, dependent: :destroy
  has_many :groups, through: :group_profiles

  before_create :generate_uuid

  validates :name, presence: true
  validates :uuid, uniqueness: true
  validates :created_at, comparison: { less_than: -> { Date.tomorrow.beginning_of_day }, message: "can't be in the future" }, allow_nil: true

  def to_param
    uuid
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
