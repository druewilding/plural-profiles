class GroupGroup < ApplicationRecord
  INCLUSION_MODES = %w[all selected none].freeze

  belongs_to :parent_group, class_name: "Group"
  belongs_to :child_group, class_name: "Group"

  has_many :inclusion_overrides, dependent: :destroy

  validates :child_group_id, uniqueness: { scope: :parent_group_id }
  validates :subgroup_inclusion_mode, inclusion: { in: INCLUSION_MODES }
  validates :profile_inclusion_mode, inclusion: { in: INCLUSION_MODES }
  validate :same_user
  validate :not_self_referencing
  validate :no_circular_reference

  scope :subgroup_all_mode, -> { where(subgroup_inclusion_mode: "all") }
  scope :subgroup_none_mode, -> { where(subgroup_inclusion_mode: "none") }
  scope :subgroup_selected, -> { where(subgroup_inclusion_mode: "selected") }

  def subgroup_all?
    subgroup_inclusion_mode == "all"
  end

  def subgroup_selected?
    subgroup_inclusion_mode == "selected"
  end

  def subgroup_none?
    subgroup_inclusion_mode == "none"
  end

  def profile_all?
    profile_inclusion_mode == "all"
  end

  def profile_selected?
    profile_inclusion_mode == "selected"
  end

  def profile_none?
    profile_inclusion_mode == "none"
  end

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

    # Use full reachability (ignoring inclusion_mode) to detect any path
    # from the prospective child back to the parent that would create a
    # cycle. descendant_group_ids considers inclusion_mode and may miss
    # paths that are relevant for circularity checks.
    if child_group.reachable_group_ids.include?(parent_group_id)
      errors.add(:child_group, "would create a circular reference")
    end
  end
end
