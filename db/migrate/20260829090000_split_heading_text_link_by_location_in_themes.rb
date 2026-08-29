class SplitHeadingTextLinkByLocationInThemes < ActiveRecord::Migration[8.1]
  # Isolated model so the migration doesn't depend on the application Theme class.
  class Theme < ActiveRecord::Base
    self.table_name = "themes"
  end

  LEGACY_TO_NEW = {
    "heading" => %w[header_title_text pane_title_text],
    "text"    => %w[header_text pane_text],
    "link"    => %w[header_link pane_link]
  }.freeze

  def up
    Theme.find_each do |theme|
      colors = theme.colors || {}
      changed = false

      LEGACY_TO_NEW.each do |old_key, new_keys|
        next unless colors.key?(old_key)

        new_keys.each { |new_key| colors[new_key] = colors[old_key] unless colors[new_key].present? }
        colors.delete(old_key)
        changed = true
      end

      theme.update_column(:colors, colors) if changed
    end
  end

  def down
    Theme.find_each do |theme|
      colors = theme.colors || {}
      changed = false

      colors["heading"] ||= colors["pane_title_text"] if colors.key?("pane_title_text")
      colors["text"]    ||= colors["pane_text"] if colors.key?("pane_text")
      colors["link"]    ||= colors["pane_link"] if colors.key?("pane_link")

      %w[header_title_text header_text header_link pane_title_text pane_text pane_link].each do |key|
        changed = true if colors.key?(key)
        colors.delete(key)
      end

      theme.update_column(:colors, colors) if changed
    end
  end
end
