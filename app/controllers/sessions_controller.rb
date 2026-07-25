class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_to_main_domain, only: :new
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    login_param = params[:login].to_s.strip
    password = params[:password].to_s

    user = if login_param.include?("@")
      User.authenticate_by(email_address: login_param, password: password)
    else
      found = User.where("lower(username) = ?", login_param.downcase).first
      if found
        User.authenticate_by(email_address: found.email_address, password: password)
      else
        User.authenticate_by(email_address: "nobody@invalid", password: password)
        nil
      end
    end

    if user && !user.deactivated?
      start_new_session_for user
      # after_authentication_url can point back to the chat. subdomain when
      # that's where the user was bounced from to sign in on the main domain
      # (see SessionsController#redirect_to_main_domain) — a legitimate
      # same-app cross-host redirect, same as redirect_to_main_domain below.
      redirect_to after_authentication_url, allow_other_host: true
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  # Signing in should be encouraged on the main domain, not the chat.
  # subdomain — bounce straight there before rendering the login form.
  def redirect_to_main_domain
    return unless request.subdomain == "chat"

    redirect_to new_session_url(host: helpers.main_site_host), allow_other_host: true
  end
end
