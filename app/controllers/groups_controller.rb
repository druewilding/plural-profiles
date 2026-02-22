class GroupsController < ApplicationController
  allow_unauthenticated_access

  def show
    @group = Group.find_by!(uuid: params[:uuid])
    @direct_profiles = @group.profiles.order(:name)
    @descendant_sections = @group.descendant_sections
  end
end
