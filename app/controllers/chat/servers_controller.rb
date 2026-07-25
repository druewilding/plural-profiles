module Chat
  class ServersController < ApplicationController
    before_action :require_membership!, only: :show
    before_action :require_owner!, only: %i[edit update]
    before_action :validate_theme_choice, only: %i[create update]

    def index
      @servers = Current.user.chat_servers.order(:name)
    end

    def show
      @channels = @server.channels.order(:name)
    end

    def new
      @server = Chat::Server.new
      load_theme_options
    end

    def create
      @server = Current.user.owned_chat_servers.build(server_params)

      Chat::Server.transaction do
        @server.save!
        @server.memberships.create!(user: Current.user, role: "owner", default_profile_id: params[:chat_server][:default_profile_id])
      end
      redirect_to chat_server_path(@server), notice: "Server created."
    rescue ActiveRecord::RecordInvalid
      load_theme_options
      render :new, status: :unprocessable_entity
    end

    def edit
      load_theme_options
    end

    def update
      @server.avatar.purge if params[:chat_server][:remove_avatar] == "1"
      if @server.update(server_params)
        redirect_to chat_server_path(@server), notice: "Server updated."
      else
        if params.dig(:chat_server, :avatar).present?
          @server.avatar.blob&.persisted? ? @server.avatar.purge_later : @server.avatar.detach
        end
        load_theme_options
        render :edit, status: :unprocessable_entity
      end
    end

    def join
      if Current.user.profiles.none?
        redirect_to new_our_profile_path, alert: "Create a profile before joining a chat server." and return
      end

      if current_membership
        redirect_to chat_server_path(@server), notice: "You're already a member." and return
      end

      @profiles = Current.user.profiles.order(:name)

      if request.post? && params[:default_profile_id].present?
        membership = @server.memberships.build(user: Current.user, role: "member", default_profile_id: params[:default_profile_id])
        if membership.save
          redirect_to chat_server_path(@server), notice: "Joined #{@server.name}."
        else
          render :join, status: :unprocessable_entity
        end
      end
    end

    private

    def load_theme_options
      @our_themes = Current.user.themes.order(:name)
      @shared_themes = Theme.shared.order(:name)
    end

    def validate_theme_choice
      theme_id = params.dig(:chat_server, :theme_id)
      return if theme_id.blank?

      allowed_ids = Current.user.theme_ids + Theme.shared.pluck(:id)
      return if allowed_ids.include?(theme_id.to_i)

      (@server ||= Chat::Server.new).errors.add(:theme, "is not available")
      load_theme_options
      render(action_name == "create" ? :new : :edit, status: :unprocessable_entity)
    end

    def server_params
      params.require(:chat_server).permit(:name, :subtitle, :theme_id, :avatar, :avatar_shape, :avatar_alt_text)
    end
  end
end
