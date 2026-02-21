class ProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @profile = Profile.find_by!(uuid: params[:uuid])
  end
end
