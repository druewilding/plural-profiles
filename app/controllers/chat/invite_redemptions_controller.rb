module Chat
  class InviteRedemptionsController < ApplicationController
    def show
      @invite = Chat::ServerInvite.unredeemed.find_by(token: params[:token])

      if @invite.nil?
        redirect_to chat_root_path, alert: "This invite link is no longer valid." and return
      end

      @server = @invite.server
      @server_theme = @server.theme

      if current_membership
        redirect_to chat_server_path(@server), notice: "You're already a member." and return
      end
    end
  end
end
