class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.find_signed!(params[:token], purpose: :email_verification)
    user.update!(email_verified_at: Time.current)
    redirect_to new_session_path, notice: "Email verified! You can now sign in."
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_session_path, alert: "Invalid or expired verification link."
  end
end
