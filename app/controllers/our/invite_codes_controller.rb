class Our::InviteCodesController < ApplicationController
  include OurSidebar

  def create
    if Current.user.invite_codes.unused.count >= InviteCode::MAX_UNUSED_PER_USER
      redirect_to our_account_path, alert: "You already have #{InviteCode::MAX_UNUSED_PER_USER} unused invite codes."
    else
      Current.user.invite_codes.create!
      redirect_to our_account_path, notice: "Invite code created."
    end
  end

  def destroy
    invite = Current.user.invite_codes.unused.find(params[:id])
    invite.destroy!
    redirect_to our_account_path, notice: "Invite code deleted."
  rescue ActiveRecord::RecordNotFound
    redirect_to our_account_path, alert: "Invite code not found or already used."
  end
end
