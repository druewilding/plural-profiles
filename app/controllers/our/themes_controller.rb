class Our::ThemesController < ApplicationController
  include OurSidebar
  before_action :set_theme, only: %i[edit update destroy activate]

  def index
    @themes = Current.user.themes.order(:name)
  end

  def new
    @theme = Current.user.themes.build(
      name: "My theme",
      colors: Theme::THEMEABLE_PROPERTIES.transform_values { |v| v[:default] }
    )
  end

  def create
    @theme = Current.user.themes.build(theme_params)
    if @theme.save
      redirect_to edit_our_theme_path(@theme), notice: "Theme created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @theme.update(theme_params)
      redirect_to edit_our_theme_path(@theme), notice: "Theme saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if Current.user.active_theme_id == @theme.id
      Current.user.update!(active_theme_id: nil)
    end
    @theme.destroy
    redirect_to our_themes_path, notice: "Theme deleted.", status: :see_other
  end

  def activate
    Current.user.update!(active_theme: @theme)
    redirect_to our_themes_path, notice: "Theme "#{@theme.name}" is now active."
  end

  def deactivate
    Current.user.update!(active_theme: nil)
    redirect_to our_themes_path, notice: "Switched back to default theme."
  end

  private

  def set_theme
    @theme = Current.user.themes.find(params[:id])
  end

  def theme_params
    params.require(:theme).permit(:name, colors: Theme::THEMEABLE_PROPERTIES.keys)
  end
end
