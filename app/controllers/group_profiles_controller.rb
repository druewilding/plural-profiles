class GroupProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @group = Group.find_by!(uuid: params[:group_uuid])
    @profile = @group.profiles.find_by!(uuid: params[:uuid])
  end
end
