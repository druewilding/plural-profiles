class CreateDuplicationWizards < ActiveRecord::Migration[8.1]
  def change
    create_table :duplication_wizards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.jsonb :state, null: false, default: {}

      t.timestamps
    end
  end
end
