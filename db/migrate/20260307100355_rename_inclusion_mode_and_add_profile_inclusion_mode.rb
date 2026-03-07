class RenameInclusionModeAndAddProfileInclusionMode < ActiveRecord::Migration[8.1]
  def up
    # Rename inclusion_mode → subgroup_inclusion_mode on both tables
    rename_column :group_groups, :inclusion_mode, :subgroup_inclusion_mode
    rename_column :inclusion_overrides, :inclusion_mode, :subgroup_inclusion_mode

    # Add the new profile columns BEFORE removing the old boolean,
    # so we can migrate data from include_direct_profiles.
    add_column :group_groups, :profile_inclusion_mode, :string, default: "all", null: false
    add_column :group_groups, :included_profile_ids, :jsonb, default: [], null: false

    add_column :inclusion_overrides, :profile_inclusion_mode, :string, default: "all", null: false
    add_column :inclusion_overrides, :included_profile_ids, :jsonb, default: [], null: false

    # Migrate data: where include_direct_profiles was false, set profile_inclusion_mode to "none"
    execute <<~SQL
      UPDATE group_groups SET profile_inclusion_mode = 'none' WHERE include_direct_profiles = FALSE;
      UPDATE inclusion_overrides SET profile_inclusion_mode = 'none' WHERE include_direct_profiles = FALSE;
    SQL

    # Now safe to drop the old boolean columns
    remove_column :group_groups, :include_direct_profiles
    remove_column :inclusion_overrides, :include_direct_profiles
  end

  def down
    # Re-add the boolean columns
    add_column :group_groups, :include_direct_profiles, :boolean, default: true, null: false
    add_column :inclusion_overrides, :include_direct_profiles, :boolean, default: true, null: false

    # Migrate data back: "none" → false, anything else → true
    execute <<~SQL
      UPDATE group_groups SET include_direct_profiles = FALSE WHERE profile_inclusion_mode = 'none';
      UPDATE inclusion_overrides SET include_direct_profiles = FALSE WHERE profile_inclusion_mode = 'none';
    SQL

    remove_column :group_groups, :included_profile_ids
    remove_column :group_groups, :profile_inclusion_mode

    remove_column :inclusion_overrides, :included_profile_ids
    remove_column :inclusion_overrides, :profile_inclusion_mode

    rename_column :group_groups, :subgroup_inclusion_mode, :inclusion_mode
    rename_column :inclusion_overrides, :subgroup_inclusion_mode, :inclusion_mode
  end
end
