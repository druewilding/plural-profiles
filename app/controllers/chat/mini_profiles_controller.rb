module Chat
  class MiniProfilesController < ApplicationController
    layout false

    POSTABLE_TYPES = { "Profile" => Profile, "Group" => Group }.freeze

    def show
      klass = POSTABLE_TYPES.fetch(params[:postable_type]) { raise ActiveRecord::RecordNotFound }
      @postable = klass.find_by!(uuid: params[:postable_uuid])
    end
  end
end
