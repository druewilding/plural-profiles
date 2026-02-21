class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :name, null: false
      t.string :pronouns
      t.text :description

      t.timestamps
    end
    add_index :profiles, :uuid, unique: true
  end
end
