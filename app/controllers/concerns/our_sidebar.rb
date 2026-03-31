module OurSidebar
  extend ActiveSupport::Concern

  included do
    before_action :set_sidebar_data
  end

  private

  def set_sidebar_data
    return unless authenticated?

    sidebar = Current.user.sidebar_tree
    @sidebar_trees = sidebar[:trees]
    @sidebar_orphan_profiles = sidebar[:orphan_profiles]
  end
end
