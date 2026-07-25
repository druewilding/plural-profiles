module Chat
  class ApplicationController < ::ApplicationController
    layout "chat"

    before_action :set_server

    private

    def set_server
      uuid = params[:server_uuid] || params[:uuid]
      return if uuid.blank?

      @server = Chat::Server.find_by!(uuid: uuid)
      @server_theme = @server.theme
    end

    def current_membership
      return nil unless @server

      @current_membership ||= @server.memberships.find_by(user: Current.user)
    end
    helper_method :current_membership

    def server_owner?
      @server && @server.owner_id == Current.user.id
    end
    helper_method :server_owner?

    def require_membership!
      return if current_membership || server_owner?

      redirect_to join_chat_server_path(@server), alert: "Join this server first."
    end

    def require_owner!
      return if server_owner?

      redirect_to chat_server_path(@server), alert: "Only the server owner can do that."
    end

    def unread_channel_ids
      @unread_channel_ids ||= Chat::ChannelRead.unread_channel_ids_for(Current.user)
    end
    helper_method :unread_channel_ids

    def unread_server_ids
      @unread_server_ids ||= Chat::ChannelRead.unread_server_ids_for(Current.user)
    end
    helper_method :unread_server_ids
  end
end
