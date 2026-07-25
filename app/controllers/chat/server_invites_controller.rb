module Chat
  class ServerInvitesController < ApplicationController
    before_action :require_owner!

    def show
      @invite = @server.server_invites.unredeemed.order(created_at: :desc).first
      @invite ||= @server.server_invites.create!(created_by: Current.user)
    end

    def create
      @server.server_invites.unredeemed.destroy_all
      @server.server_invites.create!(created_by: Current.user)
      redirect_to chat_server_invite_path(@server), notice: "New invite link generated."
    end
  end
end
