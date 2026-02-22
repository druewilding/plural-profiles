class GroupGroup < ApplicationRecord
  belongs_to :parent_group, class_name: "Group"
  belongs_to :child_group, class_name: "Group"

  validates :child_group_id, uniqueness: { scope: :parent_group_id }
  validate :same_user
  validate :not_self_referencing
  validate :no_circular_reference

  private

  def same_user
    return unless parent_group && child_group
    return if parent_group.user_id == child_group.user_id

    errors.add(:child_group, "must belong to the same user")
  end

  def not_self_referencing
    return unless parent_group_id == child_group_id

    errors.add(:child_group, "cannot be the same as the parent group")
  end

  def no_circular_reference
    return unless parent_group && child_group
    return if parent_group_id == child_group_id # already caught above

    if descendant_ids(child_group).include?(parent_group_id)
      errors.add(:child_group, "would create a circular reference")
    end
  end

  # Walk down from a given group and collect all descendant group IDs
  def descendant_ids(group, visited = Set.new)
    GroupGroup.where(parent_group_id: group.id).pluck(:child_group_id).each do |cid|
      next if visited.include?(cid)
      visited.add(cid)
      descendant_ids(Group.find(cid), visited)
    end
    visited
  end
end
