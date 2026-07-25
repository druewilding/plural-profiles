module Chat
  class ChannelDefaultProfilesController < ApplicationController
    before_action :require_membership!
    before_action :set_channel

    def update
      profile = Current.user.profiles.find_by!(uuid: params[:profile_uuid])
      default = @channel.channel_default_profiles.find_or_initialize_by(user: Current.user)
      default.profile = profile
      default.save!

      redirect_to chat_server_channel_path(@server, @channel)
    end

    private

    def set_channel
      @channel = @server.channels.find_by!(name: params[:channel_name])
    end
  end
end
