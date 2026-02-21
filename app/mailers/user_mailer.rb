class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = email_verification_url(token: user.signed_id(purpose: :email_verification, expires_in: 24.hours))
    mail to: @user.email_address, subject: "Verify your email address"
  end
end
