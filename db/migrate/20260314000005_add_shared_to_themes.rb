class AddSharedToThemes < ActiveRecord::Migration[8.1]
  def change
    add_column :themes, :shared, :boolean, default: false, null: false
    add_index :themes, :shared, where: "shared = true", name: "index_themes_on_shared"
  end
end
