class Our::SearchController < ApplicationController
  include OurSidebar

  GROUP_CONDITIONS = <<~SQL.squish.freeze
    name ILIKE :term OR subtitle ILIKE :term OR description ILIKE :term
    OR EXISTS (SELECT 1 FROM jsonb_array_elements_text(labels) AS label_val WHERE label_val ILIKE :term)
  SQL

  PROFILE_CONDITIONS = <<~SQL.squish.freeze
    name ILIKE :term OR subtitle ILIKE :term OR description ILIKE :term OR pronouns ILIKE :term
    OR EXISTS (SELECT 1 FROM jsonb_array_elements_text(labels) AS label_val WHERE label_val ILIKE :term)
  SQL

  def show
    @query = params[:q].to_s.strip

    if @query.present?
      term = "%#{Group.sanitize_sql_like(@query)}%"
      @groups = Current.user.groups.where(GROUP_CONDITIONS, term: term).order_by_name_and_labels.to_a
      @profiles = Current.user.profiles.where(PROFILE_CONDITIONS, term: term).order_by_name_and_labels.to_a
    else
      @groups = []
      @profiles = []
    end
  end
end
