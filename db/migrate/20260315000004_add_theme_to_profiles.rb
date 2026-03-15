class AddThemeToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :profiles, :theme, foreign_key: { on_delete: :nullify }, null: true
  end
end
