class RenameInclusionModeAndAddProfileInclusionMode < ActiveRecord::Migration[8.1]
  def change
    # Rename inclusion_mode → subgroup_inclusion_mode on both tables
    rename_column :group_groups, :inclusion_mode, :subgroup_inclusion_mode
    rename_column :inclusion_overrides, :inclusion_mode, :subgroup_inclusion_mode

    # Replace boolean include_direct_profiles with string profile_inclusion_mode
    # and jsonb included_profile_ids on both tables
    remove_column :group_groups, :include_direct_profiles, :boolean, default: true, null: false
    add_column :group_groups, :profile_inclusion_mode, :string, default: "all", null: false
    add_column :group_groups, :included_profile_ids, :jsonb, default: [], null: false

    remove_column :inclusion_overrides, :include_direct_profiles, :boolean, default: true, null: false
    add_column :inclusion_overrides, :profile_inclusion_mode, :string, default: "all", null: false
    add_column :inclusion_overrides, :included_profile_ids, :jsonb, default: [], null: false
  end
end
