module Chat
  class ChannelDefaultProfilesController < ApplicationController
    before_action :require_membership!
    before_action :set_channel

    def update
      profile = Current.user.profiles.find_by!(uuid: params[:profile_uuid])
      default = @channel.channel_default_profiles.find_or_initialize_by(user: Current.user)
      default.profile = profile
      default.save!

      respond_to do |format|
        # A redirect here would force a full-page Turbo visit, discarding
        # whatever the user had already typed into the message textarea —
        # replace just the picker instead, so the rest of the composer (and
        # anything mid-draft in it) is left alone.
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "posting-as-picker",
            partial: "chat/channels/posting_as_picker",
            locals: { server: @server, channel: @channel, current_profile: profile }
          )
        end
        format.html { redirect_to chat_server_channel_path(@server, @channel) }
      end
    end

    private

    def set_channel
      @channel = @server.channels.find_by!(uuid: params[:channel_uuid])
    end
  end
end
