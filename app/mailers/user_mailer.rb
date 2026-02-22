class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: user.signed_id(purpose: :email_verification, expires_in: 24.hours))
    mail to: @user.email_address, subject: "Verify your email address"
  end

  def email_change_verification(user)
    @user = user
    @new_email = user.unverified_email_address
    @verification_url = email_verification_url(token: user.signed_id(purpose: :email_change, expires_in: 24.hours))
    mail to: @new_email, subject: "Verify your new email address"
  end
end
