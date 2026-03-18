class AddDeactivatedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :deactivated_at, :datetime
  end
end
