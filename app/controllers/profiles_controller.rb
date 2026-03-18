class ProfilesController < ApplicationController
  def show
    @profile = Profile.find_by!(uuid: params[:uuid])
    @profile_theme = @profile.theme
  end
end
