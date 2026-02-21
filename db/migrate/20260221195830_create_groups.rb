class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :groups, :uuid, unique: true
  end
end
