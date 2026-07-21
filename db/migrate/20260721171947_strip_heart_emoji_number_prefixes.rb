class StripHeartEmojiNumberPrefixes < ActiveRecord::Migration[8.1]
  # Isolated model so the migration doesn't depend on the application Profile class.
  class Profile < ActiveRecord::Base
    self.table_name = "profiles"
  end

  def up
    Profile.find_each do |profile|
      next if profile.heart_emojis.blank?

      stripped = profile.heart_emojis.map { |heart| heart.sub(/\A\d+_?/, "") }
      profile.update_column(:heart_emojis, stripped) if stripped != profile.heart_emojis
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
