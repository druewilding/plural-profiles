class GroupGroup < ApplicationRecord
  INCLUSION_MODES = %w[all selected none].freeze

  belongs_to :parent_group, class_name: "Group"
  belongs_to :child_group, class_name: "Group"

  validates :child_group_id, uniqueness: { scope: :parent_group_id }
  validates :inclusion_mode, inclusion: { in: INCLUSION_MODES }
  validate :same_user
  validate :not_self_referencing
  validate :no_circular_reference

  # Backwards-compatible scopes: tests and callers may still use `nested` / `overlapping`
  scope :nested, -> { where(inclusion_mode: "all") }
  scope :overlapping, -> { where(inclusion_mode: "none") }
  scope :selected, -> { where(inclusion_mode: "selected") }

  def nested?
    inclusion_mode == "all"
  end

  def overlapping?
    inclusion_mode == "none"
  end

  def all?
    inclusion_mode == "all"
  end

  def selected?
    inclusion_mode == "selected"
  end

  def none?
    inclusion_mode == "none"
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

    if child_group.descendant_group_ids.include?(parent_group_id)
      errors.add(:child_group, "would create a circular reference")
    end
  end
end
