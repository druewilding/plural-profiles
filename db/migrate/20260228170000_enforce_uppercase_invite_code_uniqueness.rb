class EnforceUppercaseInviteCodeUniqueness < ActiveRecord::Migration[8.0]
  def up
    # Upcase any existing codes that may have slipped in before this constraint
    execute "UPDATE invite_codes SET code = upper(code)"

    # Drop the old case-sensitive unique index
    remove_index :invite_codes, :code, name: "index_invite_codes_on_code"

    # Add an expression index that enforces uniqueness at the DB level
    # regardless of case, and supports fast lookups via upper(code).
    execute <<~SQL
      CREATE UNIQUE INDEX index_invite_codes_on_upper_code
        ON invite_codes (upper(code))
    SQL
  end

  def down
    execute "DROP INDEX index_invite_codes_on_upper_code"
    add_index :invite_codes, :code, unique: true, name: "index_invite_codes_on_code"
  end
end
