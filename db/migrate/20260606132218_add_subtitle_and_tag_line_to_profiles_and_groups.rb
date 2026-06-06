class AddSubtitleAndTagLineToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :subtitle, :string
    add_column :profiles, :tag_line, :string
    add_column :groups, :subtitle, :string
    add_column :groups, :tag_line, :string
  end
end
