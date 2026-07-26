class Our::SearchController < ApplicationController
  include OurSidebar

  def show
    @query = params[:q].to_s.strip

    if @query.present?
      @groups = search(Current.user.groups, @query)
      @profiles = search(Current.user.profiles, @query)
    else
      @groups = Group.none
      @profiles = Profile.none
    end
  end

  private

  # Matches name, subtitle, description, and labels for both groups and
  # profiles; pronouns for profiles only (groups have no pronouns column,
  # but the query is only ever built against columns the relation has).
  def search(relation, query)
    term = "%#{Group.sanitize_sql_like(query)}%"
    columns = %w[name subtitle description]
    columns << "pronouns" if relation.column_names.include?("pronouns")

    column_conditions = columns.map { |column| "#{column} ILIKE :term" }.join(" OR ")
    label_condition = "EXISTS (SELECT 1 FROM jsonb_array_elements_text(labels) AS label_val WHERE label_val ILIKE :term)"

    relation
      .where("(#{column_conditions}) OR #{label_condition}", term: term)
      .order_by_name_and_labels
  end
end
