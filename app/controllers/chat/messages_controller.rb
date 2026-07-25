module Chat
  class MessagesController < ApplicationController
    before_action :require_membership!
    before_action :set_channel

    layout false, only: :index

    rate_limit to: 60, within: 1.minute, only: :create,
      with: -> { redirect_to chat_server_channel_path(@server, @channel), alert: "You're sending messages too fast — try again in a moment." }

    # Lazily loaded (via a turbo-frame with loading="lazy") as the reader scrolls
    # up through history — see app/views/chat/messages/index.html.haml for the
    # chained-frame pagination this renders.
    def index
      before_id = params[:before_id].to_i
      @messages = @channel.messages.where("id < ?", before_id).order(created_at: :desc).limit(Chat::Message::PAGE_SIZE).to_a.reverse
      @has_more_messages = @messages.any? && @channel.messages.where("id < ?", @messages.first.id).exists?
    end

    def create
      @message = @channel.messages.build(message_params.merge(user: Current.user))
      if @message.save
        redirect_to chat_server_channel_path(@server, @channel)
      else
        @messages = @channel.messages.order(created_at: :desc).limit(Chat::Message::PAGE_SIZE).to_a.reverse
        @has_more_messages = @messages.any? && @channel.messages.where("id < ?", @messages.first.id).exists?
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
