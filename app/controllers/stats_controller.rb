class StatsController < ApplicationController
  before_action :require_admin

  def index
    @user_count = User.where(deactivated_at: nil).count
    @profile_count = Profile.count
    @group_count = Group.count
    avatar_counts = ActiveStorage::Attachment.where(name: "avatar", record_type: [ Group.name, Profile.name, Chat::Server.name ]).group(:record_type).count
    @group_avatar_count = avatar_counts.fetch(Group.name, 0)
    @profile_avatar_count = avatar_counts.fetch(Profile.name, 0)
    @server_avatar_count = avatar_counts.fetch(Chat::Server.name, 0)
    @invite_code_count = InviteCode.where(redeemed_at: nil).count
    @theme_count = Theme.count
    @chat_server_count = Chat::Server.count
    @chat_channel_count = Chat::Channel.count
    @chat_message_count = Chat::Message.count
    @chat_membership_count = Chat::Membership.count
    @chat_server_invite_count = Chat::ServerInvite.unredeemed.count
  end
end
