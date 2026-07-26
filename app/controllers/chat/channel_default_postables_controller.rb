module Chat
  class ChannelDefaultPostablesController < ApplicationController
    before_action :require_membership!
    before_action :set_channel

    def update
      postable = find_postable!(params[:postable_type], params[:postable_uuid])
      default = @channel.channel_default_postables.find_or_initialize_by(user: Current.user)
      default.postable = postable
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
            locals: { server: @server, channel: @channel, current_postable: postable }
          )
        end
        format.html { redirect_to chat_server_channel_path(@server, @channel) }
      end
    end

    private

    def set_channel
      @channel = @server.channels.find_by!(uuid: params[:channel_uuid])
    end

    # Deliberately a closed case/when rather than params[:postable_type].constantize
    # — the type comes straight from request params, and constantizing
    # arbitrary user input onto a polymorphic association is a classic way to
    # let an attacker point it at a model it was never meant to reference.
    def find_postable!(type, uuid)
      case type
      when "Group" then Current.user.groups.find_by!(uuid: uuid)
      else Current.user.profiles.find_by!(uuid: uuid)
      end
    end
  end
end
