class Group < ApplicationRecord
  belongs_to :user
  has_many :group_profiles, dependent: :destroy
  has_many :profiles, through: :group_profiles

  has_many :parent_links, class_name: "GroupGroup", foreign_key: :child_group_id, dependent: :destroy
  has_many :child_links, class_name: "GroupGroup", foreign_key: :parent_group_id, dependent: :destroy
  has_many :parent_groups, through: :parent_links, source: :parent_group
  has_many :child_groups, through: :child_links, source: :child_group

  has_one_attached :avatar

  before_create :generate_uuid

  validates :name, presence: true
  validates :uuid, uniqueness: true

  def to_param
    uuid
  end

  # Collect all profiles from this group and all descendant groups.
  # Profiles may appear in multiple sub-groups; the result is de-duplicated.
  def all_profiles(visited = Set.new)
    return Profile.none if visited.include?(id)
    visited.add(id)

    ids = profile_ids
    child_groups.each do |child|
      ids += child.all_profiles(visited).pluck(:id)
    end
    Profile.where(id: ids.uniq)
  end

  # Collect all descendant groups (recursive, de-duplicated)
  def all_child_groups(visited = Set.new)
    return Group.none if visited.include?(id)
    visited.add(id)

    ids = child_group_ids
    child_groups.each do |child|
      ids += child.all_child_groups(visited).pluck(:id)
    end
    Group.where(id: ids.uniq)
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
