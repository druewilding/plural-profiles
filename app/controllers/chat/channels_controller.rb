module Chat
  class ChannelsController < ApplicationController
    before_action :require_membership!
    before_action :set_channel, only: %i[show edit update]
    before_action :require_owner!, only: %i[new create edit update]
    before_action :validate_theme_choice, only: %i[create update]

    def show
      @messages = @channel.messages.order(created_at: :desc).limit(Chat::Message::PAGE_SIZE).to_a.reverse
      @has_more_messages = @messages.any? && @channel.messages.where("id < ?", @messages.first.id).exists?
      @message = @channel.messages.build
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
      @channel = @server.channels.find_by!(name: params[:name])
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
      params.require(:chat_channel).permit(:name, :subtitle, :theme_id)
    end
  end
end
