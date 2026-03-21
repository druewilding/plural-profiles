class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username"
  end
end
