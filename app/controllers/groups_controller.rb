class GroupsController < ApplicationController
  def show
    @group = Group.find_by!(uuid: params[:uuid])
    @group_theme = @group.theme
    @direct_profiles = @group.visible_root_profiles
    @direct_child_groups = @group.visible_direct_child_groups
    @seen_profile_ids = Set.new
    @descendant_tree = @group.descendant_tree(seen_profile_ids: @seen_profile_ids)
  end

  def panel
    @group = Group.find_by!(uuid: params[:uuid])
    @group_theme = @group.theme

    if params[:root].present? && params[:root] != params[:uuid]
      root_group = Group.find_by!(uuid: params[:root])
      path = Array(params[:path]).map(&:to_i)
      @profiles = @group.profiles_visible_at_path(path, root_group_id: root_group.id)
      @sub_groups = @group.visible_direct_child_groups(path: path, root_group_id: root_group.id)
      @root_uuid = params[:root]
      @current_path = path
    else
      @profiles = @group.visible_root_profiles
      @sub_groups = @group.visible_direct_child_groups
      @root_uuid = @group.uuid
      @current_path = []
    end

    render partial: "groups/group_content", locals: { group: @group, profiles: @profiles, sub_groups: @sub_groups, root_uuid: @root_uuid, current_path: @current_path }, layout: false
  end
end
