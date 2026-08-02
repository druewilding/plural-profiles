class AddChatIdentityFieldsToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :mini_profile_name, :string
    add_column :profiles, :mini_profile_name_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_subtitle, :string
    add_column :profiles, :mini_profile_subtitle_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_tag_line, :string
    add_column :profiles, :mini_profile_tag_line_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_description, :text
    add_column :profiles, :mini_profile_description_inherited, :boolean, default: false, null: false
    add_column :profiles, :mini_profile_pronouns, :string
    add_column :profiles, :mini_profile_pronouns_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_heart_emojis, :jsonb, default: [], null: false
    add_column :profiles, :mini_profile_heart_emojis_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_avatar_alt_text, :string
    add_column :profiles, :mini_profile_avatar_shape, :string, default: "rounded", null: false
    add_column :profiles, :mini_profile_avatar_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_link_enabled, :boolean, default: false, null: false

    add_column :groups, :mini_profile_name, :string
    add_column :groups, :mini_profile_name_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_subtitle, :string
    add_column :groups, :mini_profile_subtitle_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_tag_line, :string
    add_column :groups, :mini_profile_tag_line_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_description, :text
    add_column :groups, :mini_profile_description_inherited, :boolean, default: false, null: false
    add_column :groups, :mini_profile_avatar_alt_text, :string
    add_column :groups, :mini_profile_avatar_shape, :string, default: "rounded", null: false
    add_column :groups, :mini_profile_avatar_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_link_enabled, :boolean, default: false, null: false
  end
end
