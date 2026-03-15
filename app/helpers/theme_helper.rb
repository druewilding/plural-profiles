module ThemeHelper
  def active_theme_style
    override = authenticated? && Current.user&.override_group_themes?

    # Logged-in user with an active theme
    if authenticated? && Current.user&.active_theme
      # Use own theme if: override is on, or there is no group theme to show
      return Current.user.active_theme.to_css_properties if override || !@group_theme
    end

    # Group theme (skipped entirely if the user has override on, even without an active theme)
    return @group_theme.to_css_properties if @group_theme && !override

    # Fallback: site default
    Theme.site_default_theme&.to_css_properties
  end
end
