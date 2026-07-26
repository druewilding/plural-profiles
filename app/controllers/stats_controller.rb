class StatsController < ApplicationController
  before_action :require_admin

  def index
    @user_count = User.where(deactivated_at: nil).count
    @profile_count = Profile.count
    @group_count = Group.count
    @avatar_count = ActiveStorage::Attachment.where(name: "avatar", record_type: [ "Profile", "Group" ]).count
    @invite_code_count = InviteCode.where(redeemed_at: nil).count
    @theme_count = Theme.count
    @chat_server_count = Chat::Server.count
    @chat_channel_count = Chat::Channel.count
    @chat_message_count = Chat::Message.count
    @chat_membership_count = Chat::Membership.count
    @chat_server_invite_count = Chat::ServerInvite.unredeemed.count
  end
end
