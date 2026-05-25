class AddAvatarShapeToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :avatar_shape, :string, default: "rounded", null: false
    add_column :groups,   :avatar_shape, :string, default: "rounded", null: false
  end
end
