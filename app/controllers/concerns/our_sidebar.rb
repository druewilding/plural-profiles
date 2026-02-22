module OurSidebar
  extend ActiveSupport::Concern

  included do
    before_action :set_sidebar_data
  end

  private

  def set_sidebar_data
    return unless authenticated?

    @sidebar_profiles = Current.user.profiles.order(:name)
    @sidebar_groups = Current.user.groups.order(:name)
  end
end
