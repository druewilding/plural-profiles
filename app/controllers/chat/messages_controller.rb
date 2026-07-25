module Chat
  class MessagesController < ApplicationController
    before_action :require_membership!
    before_action :set_channel

    rate_limit to: 60, within: 1.minute, only: :create,
      with: -> { redirect_to chat_server_channel_path(@server, @channel), alert: "You're sending messages too fast — try again in a moment." }

    def create
      @message = @channel.messages.build(message_params.merge(user: Current.user))
      if @message.save
        redirect_to chat_server_channel_path(@server, @channel)
      else
        @messages = @channel.messages.order(:created_at)
        render "chat/channels/show", status: :unprocessable_entity
      end
    end

    private

    def set_channel
      @channel = @server.channels.find_by!(name: params[:channel_name])
      @channel_theme = @channel.theme
    end

    def message_params
      params.require(:chat_message).permit(:body)
    end
  end
end
