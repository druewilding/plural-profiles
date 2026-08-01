module Chat
  class ChannelsController < ApplicationController
    before_action :require_membership!
    before_action :set_channel, only: %i[show edit update mark_read]
    before_action :require_owner!, only: %i[new create edit update]
    before_action :validate_theme_choice, only: %i[create update]

    def show
      @messages = Chat::Message.latest_page(@channel.messages)
      @has_more_messages = @messages.any? && @channel.messages.before_cursor(@messages.first).exists?
      @message = @channel.messages.build
      @in_channel_chat = true
    end

    # Deliberately not a side effect of the `show` GET — Turbo 8 prefetches
    # links on hover, and a GET action that marks the channel as read would
    # silently clear the unread dot the moment the pointer passed over the
    # sidebar link, before the reader ever actually opened it. The client only
    # calls this once the page has genuinely mounted (see channel_read_controller.js).
    def mark_read
      Chat::ChannelRead.mark_read!(Current.user, @channel)
      broadcast_own_read_state
      head :no_content
    end

    def new
      @channel = @server.channels.new
      load_theme_options
    end

    def create
      @channel = @server.channels.build(channel_params)
      if @channel.save
        redirect_to chat_server_channel_path(@server, @channel), notice: "Channel created."
      else
        load_theme_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_theme_options
    end

    def update
      if @channel.update(channel_params)
        redirect_to chat_server_channel_path(@server, @channel), notice: "Channel updated."
      else
        load_theme_options
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_channel
      @channel = @server.channels.find_by!(uuid: params[:uuid])
      @channel_theme = @channel.theme
    end

    def load_theme_options
      @our_themes = Current.user.themes.order(:name)
      @shared_themes = Theme.shared.order(:name)
    end

    def validate_theme_choice
      theme_id = params.dig(:chat_channel, :theme_id)
      return if theme_id.blank?

      allowed_ids = Current.user.theme_ids + Theme.shared.pluck(:id)
      return if allowed_ids.include?(theme_id.to_i)

      (@channel ||= @server.channels.new).errors.add(:theme, "is not available")
      load_theme_options
      render(action_name == "create" ? :new : :edit, status: :unprocessable_entity)
    end

    def channel_params
      params.require(:chat_channel).permit(:name, :subtitle, :description, :theme_id)
    end

    # Keeps the reader's own sidebar in sync live too — without this, the
    # rail/pane dots for the channel just read would only clear on the next
    # full page load, since marking read now happens after the page has
    # already rendered (see the comment on #mark_read above).
    def broadcast_own_read_state
      @channel.broadcast_replace_to [ Current.user, @server, :chat_channel_pane ],
        target: "channel_#{@channel.id}_sidebar_dot",
        partial: "chat/shared/channel_dot", locals: { channel: @channel, unread: false }

      still_unread = Chat::ChannelRead.unread_server_ids_for(Current.user).include?(@server.id)
      @channel.broadcast_replace_to [ Current.user, :chat_server_rail ],
        target: "server_#{@server.id}_rail_dot",
        partial: "chat/shared/server_dot", locals: { server: @server, unread: still_unread }
    end
  end
end
