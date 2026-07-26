module HasLabels
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_labels

    # Order by name (case-insensitive), then unlabelled items first, then labels alphabetically.
    # COLLATE "C" sorts by raw codepoint order rather than the database's locale-aware
    # collation, so leading symbols (e.g. "~") sort after letters instead of being
    # ignored — matching the in-memory ordering from #name_and_label_sort_key.
    scope :order_by_name_and_labels, -> {
      order(Arel.sql(%q{LOWER(name) COLLATE "C", CASE WHEN labels = '[]'::jsonb THEN 0 ELSE 1 END, LOWER(labels::text) COLLATE "C"}))
    }
  end

  # Returns labels as a comma-separated string, for use in text fields.
  def labels_text
    labels.join(", ")
  end

  # Accepts a comma-separated string and populates the labels array.
  def labels_text=(value)
    self.labels = value.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  # Sort key for in-memory ordering: name first (case-insensitive), unlabelled before labelled,
  # then labels alphabetically.
  def name_and_label_sort_key
    [ name.downcase, labels.empty? ? 0 : 1, labels.join(", ").downcase ]
  end

  private

  def normalize_labels
    self.labels = Array(labels).map { |l| l.to_s.strip }.reject(&:blank?).uniq
  end
end
